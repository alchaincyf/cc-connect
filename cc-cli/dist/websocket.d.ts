type MessageHandler = (msg: any) => void;
type DisconnectHandler = () => void;
export declare class WebSocketClient {
    private ws;
    private serverUrl;
    private sessionId;
    private secret;
    private messageHandler;
    private disconnectHandler;
    private reconnectAttempts;
    private maxReconnectAttempts;
    private reconnectDelay;
    private pingInterval;
    constructor(serverUrl: string, sessionId: string, secret: string);
    connect(): Promise<void>;
    private startPingInterval;
    private stopPingInterval;
    private attemptReconnect;
    send(msg: any): void;
    onMessage(handler: MessageHandler): void;
    onDisconnect(handler: DisconnectHandler): void;
    close(): void;
    get isConnected(): boolean;
}
export {};
//# sourceMappingURL=websocket.d.ts.map