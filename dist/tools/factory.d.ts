import { RobloxResponse } from "../bridge/types.js";
export declare const DEFAULT_TOOL_OUTPUT_CHAR_LIMIT = 6000;
export declare const HARD_TOOL_OUTPUT_CHAR_LIMIT = 32000;
export declare const MAX_ERROR_RESPONSE_CHARS = 500;
/**
 * Check if the current instance is a secondary relay.
 * Secondaries can be created either via --baseurl or automatically when
 * the port is already in use (EADDRINUSE fallback).
 */
export declare function isSecondaryRelay(): boolean;
/**
 * Relay a tool call to the primary's /api/tool HTTP endpoint.
 * Handles both immediate results and progress-job-based async responses
 * (polls /api/tool-progress until done).
 */
export declare function relayToolToApi(type: string, params: Record<string, unknown>, timeoutMs?: number, outputOptions?: ToolOutputOptions): Promise<ToolTextResponse>;
export interface ToolTextResponse {
    [x: string]: unknown;
    content: {
        type: "text";
        text: string;
    }[];
    isError?: boolean;
}
export interface ToolOutputOptions {
    maxOutputChars?: number;
    defaultMaxOutputChars?: number;
    truncationHint?: string;
}
export declare function normalizeMaxOutputChars(value: unknown, fallback?: number): number;
export declare function formatToolText(text: string, options?: ToolOutputOptions): string;
export declare function toolTextResponse(text: string, options?: ToolOutputOptions, isError?: boolean): ToolTextResponse;
/**
 * Build a compact one-line stamp identifying the client a result came from,
 * so the model does not blend stale results across clients (context poisoning).
 * Returns "" when it can't be resolved (e.g. secondary relay).
 */
export declare function clientStampPrefix(): string;
/**
 * Summarize a Roblox response for an error message without dumping the entire
 * (potentially large) object into the model context.
 */
export declare function describeResponse(response: RobloxResponse | undefined): string;
export interface SendAndWaitOptions {
    type: string;
    data: Record<string, unknown>;
    timeoutMs?: number;
    maxOutputChars?: number;
    truncationHint?: string;
    failureField?: "output" | "error";
    failureMessage?: (response: RobloxResponse | undefined) => string;
    successMessage?: (response: RobloxResponse) => string;
    /** When true, prepend a one-line client identity stamp to successful output. */
    stampClient?: boolean;
}
/**
 * Dispatch a request to the Roblox client and wait for the response.
 * Handles the no-client / invalid-client / timeout boilerplate that every
 * tool used to repeat.
 */
export declare function sendAndWait(options: SendAndWaitOptions): Promise<ToolTextResponse>;
export interface FireAndForgetOptions {
    type: string;
    data: Record<string, unknown>;
    successMessage: string;
}
/**
 * Dispatch a request without waiting for a response.
 * Returns a success message once the request has been queued/sent.
 */
export declare function sendFireAndForget(options: FireAndForgetOptions): ToolTextResponse;
