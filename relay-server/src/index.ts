/**
 * CC Connect 中继服务
 * 使用 Cloudflare Workers + Durable Objects
 */

export interface Env {
  SESSIONS: DurableObjectNamespace;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // WebSocket 连接: /ws/:sessionId
    if (path.startsWith('/ws/')) {
      const sessionId = path.split('/')[2];
      if (!sessionId) {
        return new Response('Missing session ID', { status: 400 });
      }

      const id = env.SESSIONS.idFromName(sessionId);
      const stub = env.SESSIONS.get(id);
      return stub.fetch(request);
    }

    // 健康检查
    if (path === '/health') {
      return new Response('OK', { status: 200 });
    }

    return new Response('CC Connect Relay Server', { status: 200 });
  },
};

// Session Durable Object
export class SessionDO {
  private state: DurableObjectState;

  constructor(state: DurableObjectState) {
    this.state = state;
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const upgradeHeader = request.headers.get('Upgrade');

    if (upgradeHeader !== 'websocket') {
      return new Response('Expected WebSocket', { status: 426 });
    }

    const token = url.searchParams.get('token');
    const clientType = url.searchParams.get('type');

    if (!clientType || !['cli', 'app'].includes(clientType)) {
      return new Response('Invalid client type', { status: 400 });
    }

    // 从持久化存储获取 secret
    const storedSecret = await this.state.storage.get<string>('sessionSecret');

    // CLI 首次连接设置 secret
    if (clientType === 'cli') {
      if (!token) {
        return new Response('Token required', { status: 401 });
      }
      if (storedSecret === undefined) {
        // 首次连接，保存 secret
        await this.state.storage.put('sessionSecret', token);
      } else if (storedSecret !== token) {
        return new Response('Invalid token', { status: 401 });
      }
    }

    // App 连接验证 token
    if (clientType === 'app') {
      if (!token || token !== storedSecret) {
        return new Response('Invalid token', { status: 401 });
      }
    }

    // 创建 WebSocket
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);

    this.state.acceptWebSocket(server, [clientType]);

    // App 连接成功后通知 CLI
    if (clientType === 'app') {
      const cliSockets = this.state.getWebSockets('cli');
      for (const ws of cliSockets) {
        try {
          ws.send(JSON.stringify({ type: 'paired' }));
        } catch (e) {
          // ignore
        }
      }
    }

    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    const tags = this.state.getTags(ws);
    const isFromCli = tags.includes('cli');

    // 转发消息到对端
    const targetTag = isFromCli ? 'app' : 'cli';
    const targets = this.state.getWebSockets(targetTag);

    for (const target of targets) {
      try {
        target.send(message);
      } catch (e) {
        // ignore errors
      }
    }

    // 处理 ping
    if (typeof message === 'string') {
      try {
        const msg = JSON.parse(message);
        if (msg.type === 'ping') {
          ws.send(JSON.stringify({ type: 'pong' }));
        }
      } catch {
        // 非 JSON
      }
    }
  }

  async webSocketClose(ws: WebSocket, code: number, reason: string) {
    const tags = this.state.getTags(ws);

    // 通知对端断开
    if (tags.includes('cli')) {
      const appSockets = this.state.getWebSockets('app');
      for (const app of appSockets) {
        try {
          app.send(JSON.stringify({ type: 'cli_disconnected' }));
        } catch (e) {}
      }
    } else if (tags.includes('app')) {
      const cliSockets = this.state.getWebSockets('cli');
      for (const cli of cliSockets) {
        try {
          cli.send(JSON.stringify({ type: 'app_disconnected' }));
        } catch (e) {}
      }
    }
  }

  async webSocketError(ws: WebSocket, error: unknown) {
    console.error('WebSocket error:', error);
  }
}
