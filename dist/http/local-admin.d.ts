import type { IncomingMessage } from "node:http";
export declare const LOCAL_ADMIN_HEADER = "x-roblox-mcp-admin-token";
export declare function canIssueLocalAdminToken(req: IncomingMessage): boolean;
export declare function getLocalAdminToken(): string;
export declare function isAuthorizedLocalAdminRequest(req: IncomingMessage): boolean;
