import net from "net";
import { tmpdir } from "os";
import process from "node:process";

export interface DiscordActivityAssets {
    large_image?: string;
    large_text?: string;
    small_image?: string;
    small_text?: string;
}

export interface DiscordActivity {
    details?: string;
    state?: string;
    assets?: DiscordActivityAssets;
    timestamps?: {
        start?: number;
    };
}

export interface DiscordIpcConnection {
    setActivity: (activity: DiscordActivity | null) => Promise<void>;
    close: () => void;
    isConnected: () => boolean;
}

type PendingCommand = {
    nonce: string;
    resolve: () => void;
    reject: (err: Error) => void;
};

const OP_HANDSHAKE = 0;
const OP_FRAME = 1;
const OP_CLOSE = 2;
const OP_PING = 3;
const OP_PONG = 4;

function pipeCandidates(): string[] {
    const paths: string[] = [];
    if (process.platform === "win32") {
        for (let i = 0; i < 10; i += 1)
            paths.push(`\\\\.\\pipe\\discord-ipc-${i}`);
        return paths;
    }
    const xdg = process.env.XDG_RUNTIME_DIR;
    const tmp = tmpdir();
    const dirs = xdg && xdg !== tmp ? [xdg, tmp] : [tmp];
    for (const dir of dirs) {
        for (let i = 0; i < 10; i += 1) {
            paths.push(`${dir}/discord-ipc-${i}`);
        }
    }
    return paths;
}

function encodeFrame(op: number, payload: Record<string, unknown>): Buffer {
    const data = Buffer.from(JSON.stringify(payload), "utf8");
    const header = Buffer.alloc(8);
    header.writeUInt32LE(op, 0);
    header.writeUInt32LE(data.length, 4);
    return Buffer.concat([header, data]);
}

function tryConnectPipe(path: string, timeoutMs: number): Promise<net.Socket> {
    return new Promise((resolve, reject) => {
        const socket = net.createConnection(path);
        const fail = (err: Error) => {
            socket.destroy();
            reject(err);
        };
        socket.once("connect", () => {
            socket.removeAllListeners("error");
            resolve(socket);
        });
        socket.once("error", fail);
        const timer = setTimeout(() => fail(new Error("connect timeout")), timeoutMs);
        socket.once("connect", () => clearTimeout(timer));
        socket.once("error", () => clearTimeout(timer));
    });
}

export class DiscordRpcError extends Error {
    constructor(message: string) {
        super(message);
        this.name = "DiscordRpcError";
    }
}

export async function connectDiscordIpc(clientId: string): Promise<DiscordIpcConnection> {
    if (!/^\d{5,25}$/.test(clientId)) {
        throw new DiscordRpcError(
            `Invalid Discord application client ID: "${clientId}". ` +
                "Create a Discord application, copy its Application ID, and pass it as clientId (or set DISCORD_RPC_CLIENT_ID).",
        );
    }
    let lastError: Error | null = null;
    for (const pipe of pipeCandidates()) {
        let socket: net.Socket;
        try {
            socket = await tryConnectPipe(pipe, 1500);
        }
        catch (err) {
            lastError = err as Error;
            continue;
        }
        try {
            return await handshake(socket, clientId);
        }
        catch (err) {
            lastError = err as Error;
        }
    }
    throw new DiscordRpcError(
        `Could not connect to the local Discord client over IPC: ${lastError?.message ?? "no pipe reachable"}. ` +
            "Make sure the Discord desktop app is running on this machine.",
    );
}

interface FrameContext {
    socket: net.Socket;
    clientId: string;
    pending: Map<string, PendingCommand>;
    connected: boolean;
}

function attachFrameParsing(ctx: FrameContext, onFrame: (payload: Record<string, unknown>) => void): (err: Error) => void {
    let buffer = Buffer.alloc(0);
    ctx.socket.on("data", (chunk: Buffer) => {
        buffer = Buffer.concat([buffer, chunk]);
        while (buffer.length >= 8) {
            const op = buffer.readUInt32LE(0);
            const len = buffer.readUInt32LE(4);
            if (buffer.length < 8 + len)
                return;
            const payloadRaw = buffer.subarray(8, 8 + len).toString("utf8");
            buffer = buffer.subarray(8 + len);
            let payload: Record<string, unknown>;
            try {
                payload = JSON.parse(payloadRaw);
            }
            catch {
                continue;
            }
            if (op === OP_HANDSHAKE || op === OP_FRAME) {
                const evt = (payload as { evt?: string }).evt;
                if (evt === "ERROR") {
                    const nonce = typeof payload.nonce === "string" ? payload.nonce : undefined;
                    const pendingCmd = nonce ? ctx.pending.get(nonce) : undefined;
                    if (pendingCmd && nonce) {
                        ctx.pending.delete(nonce);
                        pendingCmd.reject(
                            new DiscordRpcError(
                                String((payload as { data?: { message?: string } }).data?.message ?? payloadRaw),
                            ),
                        );
                    }
                }
                else if (typeof payload.nonce === "string" && ctx.pending.has(payload.nonce)) {
                    const cmd = ctx.pending.get(payload.nonce);
                    ctx.pending.delete(payload.nonce);
                    cmd?.resolve();
                }
                onFrame(payload);
            }
            if (op === OP_PING) {
                const data = Buffer.from(JSON.stringify(payload), "utf8");
                const header = Buffer.alloc(8);
                header.writeUInt32LE(OP_PONG, 0);
                header.writeUInt32LE(data.length, 4);
                ctx.socket.write(Buffer.concat([header, data]));
            }
        }
    });
    return (err: Error) => {
        for (const cmd of ctx.pending.values())
            cmd.reject(new DiscordRpcError(`Discord IPC connection failed: ${err.message}`));
        ctx.pending.clear();
    };
}

function handshake(socket: net.Socket, clientId: string): Promise<DiscordIpcConnection> {
    return new Promise((resolve, reject) => {
        let connected = false;
        const pending = new Map<string, PendingCommand>();
        const timer = setTimeout(() => {
            if (!connected) {
                socket.destroy();
                reject(new DiscordRpcError("Timed out waiting for Discord IPC handshake."));
            }
        }, 5000);

        const failPending = attachFrameParsing({ socket, clientId, pending, connected: false }, (payload) => {
            const evt = (payload as { evt?: string }).evt;
            if (evt === "ERROR" && !connected) {
                clearTimeout(timer);
                socket.destroy();
                reject(new DiscordRpcError(JSON.stringify(payload)));
                return;
            }
            if (!connected) {
                connected = true;
                clearTimeout(timer);
                resolve(makeConnection(socket, clientId, pending));
            }
        });
        socket.once("error", (err) => {
            clearTimeout(timer);
            failPending(err);
            if (!connected)
                reject(err);
        });
        socket.once("close", () => {
            clearTimeout(timer);
            if (!connected)
                reject(new DiscordRpcError("Discord IPC socket closed during handshake."));
        });
        socket.write(encodeFrame(OP_HANDSHAKE, { v: 1, client_id: clientId }));
    });
}

function makeConnection(
    socket: net.Socket,
    clientId: string,
    pending: Map<string, PendingCommand>,
): DiscordIpcConnection {
    let closed = false;
    const rejectAllPending = () => {
        for (const cmd of pending.values())
            cmd.reject(new DiscordRpcError("Discord IPC connection closed."));
        pending.clear();
    };
    socket.once("close", () => {
        closed = true;
        rejectAllPending();
    });
    return {
        isConnected() {
            return !closed && !socket.destroyed;
        },
        close() {
            if (!closed) {
                closed = true;
                socket.write(encodeFrame(OP_CLOSE, {}));
            }
            socket.destroy();
            rejectAllPending();
        },
        setActivity(activity) {
            if (closed || socket.destroyed) {
                return Promise.reject(new DiscordRpcError("Discord IPC connection is closed."));
            }
            const nonce = Math.random().toString(36).slice(2);
            const frame = encodeFrame(OP_FRAME, {
                v: 1,
                client_id: clientId,
                nonce,
                args: {
                    pid: process.pid,
                    activity: activity ?? undefined,
                },
            });
            return new Promise<void>((resolve, reject) => {
                const entry: PendingCommand = { nonce, resolve, reject };
                pending.set(nonce, entry);
                socket.write(frame, (err) => {
                    if (err)
                        reject(err);
                });
                setTimeout(() => {
                    if (pending.delete(nonce)) {
                        reject(new DiscordRpcError("Timed out setting Discord activity."));
                    }
                }, 5000);
            });
        },
    };
}
