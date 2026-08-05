import type { WebSocket } from "ws";
export type InstanceRole = "primary" | "secondary";
export interface MobileCapabilities {
    [key: string]: boolean;
}
export interface RobloxClient {
    clientId: string;
    sessionId?: string;
    username: string;
    userId: number;
    placeId: number;
    jobId: string;
    placeName: string;
    transport: "ws" | "http";
    ws?: WebSocket;
    lastHttpPoll: number;
    pendingHttpCommands: string[];
    pendingPollResolve: ((commands: string[]) => void) | null;
    mobile?: boolean;
    executor?: string;
    platform?: string;
    capabilities?: MobileCapabilities;
}
export interface RobloxResponse {
    id: string;
    output?: string;
    error?: string;
    [key: string]: unknown;
}
export type ResponseResolver = (data: RobloxResponse) => void;
export const NO_CLIENT_SENTINEL = null;
export const INVALID_CLIENT_SENTINEL = "INVALID_CLIENT";
export type DispatchResult = string | null | "INVALID_CLIENT";
