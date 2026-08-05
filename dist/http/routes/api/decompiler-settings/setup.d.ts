import type { IncomingMessage, ServerResponse } from "node:http";
import { type DecompilerSettings, type DecompilerProviderId } from "../../../../decompiler/settings.js";
type SetupProviderId = Extract<DecompilerProviderId, "shiny" | "fission">;
interface SetupResponse {
    ok: boolean;
    provider: SetupProviderId;
    endpoint?: string | null;
    repoPath?: string;
    binaryPath?: string | null;
    runCommand?: string | null;
    logPath?: string | null;
    started?: boolean;
    alreadyRunning?: boolean;
    output?: string;
    error?: string | null;
}
export declare function isLocalDecompilerSetupRequest(req: IncomingMessage): boolean;
export declare function ensureLocalDecompilerProviderRunning(provider: SetupProviderId, configuredEndpoint?: string): Promise<SetupResponse>;
export declare function ensureConfiguredLocalDecompilerProvidersRunning(settings: DecompilerSettings): Promise<SetupResponse[]>;
export declare function GET(req: IncomingMessage, res: ServerResponse, url: URL): Promise<void>;
export declare function POST(req: IncomingMessage, res: ServerResponse): Promise<void>;
export {};
