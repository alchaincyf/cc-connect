"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebSocketClient = void 0;
const ws_1 = __importDefault(require("ws"));
class WebSocketClient {
    ws = null;
    serverUrl;
    sessionId;
    secret;
    messageHandler = null;
    disconnectHandler = null;
    reconnectAttempts = 0;
    maxReconnectAttempts = 5;
    reconnectDelay = 3000;
    pingInterval = null;
    constructor(serverUrl, sessionId, secret) {
        this.serverUrl = serverUrl;
        this.sessionId = sessionId;
        this.secret = secret;
    }
    async connect() {
        return new Promise((resolve, reject) => {
            const url = `${this.serverUrl}/ws/${this.sessionId}?token=${this.secret}&type=cli`;
            this.ws = new ws_1.default(url);
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
                }
                catch (e) {
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
    startPingInterval() {
        this.pingInterval = setInterval(() => {
            this.send({ type: 'ping' });
        }, 30000);
    }
    stopPingInterval() {
        if (this.pingInterval) {
            clearInterval(this.pingInterval);
            this.pingInterval = null;
        }
    }
    async attemptReconnect() {
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
        }
        catch (e) {
            // connect 会触发 onClose，自动继续重连
        }
    }
    send(msg) {
        if (this.ws?.readyState === ws_1.default.OPEN) {
            this.ws.send(JSON.stringify(msg));
        }
    }
    onMessage(handler) {
        this.messageHandler = handler;
    }
    onDisconnect(handler) {
        this.disconnectHandler = handler;
    }
    close() {
        this.stopPingInterval();
        this.maxReconnectAttempts = 0; // 阻止重连
        this.ws?.close();
        this.ws = null;
    }
    get isConnected() {
        return this.ws?.readyState === ws_1.default.OPEN;
    }
}
exports.WebSocketClient = WebSocketClient;
//# sourceMappingURL=websocket.js.map