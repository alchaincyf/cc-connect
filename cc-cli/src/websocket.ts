import WebSocket from 'ws';

type MessageHandler = (msg: any) => void;
type DisconnectHandler = () => void;

export class WebSocketClient {
  private ws: WebSocket | null = null;
  private serverUrl: string;
  private sessionId: string;
  private secret: string;
  private messageHandler: MessageHandler | null = null;
  private disconnectHandler: DisconnectHandler | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 3000;
  private pingInterval: NodeJS.Timeout | null = null;

  constructor(serverUrl: string, sessionId: string, secret: string) {
    this.serverUrl = serverUrl;
    this.sessionId = sessionId;
    this.secret = secret;
  }

  async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      const url = `${this.serverUrl}/ws/${this.sessionId}?token=${this.secret}&type=cli`;

      this.ws = new WebSocket(url);

      const timeout = setTimeout(() => {
        this.ws?.close();
        reject(new Error('连接超时'));
      }, 10000);

      this.ws.on('open', () => {
        clearTimeout(timeout);
        this.reconnectAttempts = 0;
        this.startPingInterval();
        resolve();
      });

      this.ws.on('message', (data) => {
        try {
          const msg = JSON.parse(data.toString());
          this.messageHandler?.(msg);
        } catch (e) {
          console.error('解析消息失败:', e);
        }
      });

      this.ws.on('close', () => {
        this.stopPingInterval();
        this.disconnectHandler?.();
        this.attemptReconnect();
      });

      this.ws.on('error', (error) => {
        clearTimeout(timeout);
        if (this.reconnectAttempts === 0) {
          reject(error);
        }
      });
    });
  }

  private startPingInterval(): void {
    this.pingInterval = setInterval(() => {
      this.send({ type: 'ping' });
    }, 30000);
  }

  private stopPingInterval(): void {
    if (this.pingInterval) {
      clearInterval(this.pingInterval);
      this.pingInterval = null;
    }
  }

  private async attemptReconnect(): Promise<void> {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('重连失败次数过多，放弃重连');
      return;
    }

    this.reconnectAttempts++;
    console.log(`尝试重连 (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);

    await new Promise((resolve) => setTimeout(resolve, this.reconnectDelay));

    try {
      await this.connect();
      console.log('✅ 重连成功');
    } catch (e) {
      // connect 会触发 onClose，自动继续重连
    }
  }

  send(msg: any): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(msg));
    }
  }

  onMessage(handler: MessageHandler): void {
    this.messageHandler = handler;
  }

  onDisconnect(handler: DisconnectHandler): void {
    this.disconnectHandler = handler;
  }

  close(): void {
    this.stopPingInterval();
    this.maxReconnectAttempts = 0; // 阻止重连
    this.ws?.close();
    this.ws = null;
  }

  get isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }
}
