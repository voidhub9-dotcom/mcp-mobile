import type { IncomingMessage, ServerResponse } from "http";
/**
 * Dashboard-only image route. Generic /api/tool output is deliberately
 * truncated; screenshots must preserve the full base64 payload.
 */
export declare function POST(req: IncomingMessage, res: ServerResponse): Promise<void>;
