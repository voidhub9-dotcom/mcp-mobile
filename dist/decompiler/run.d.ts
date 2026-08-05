import { type DecompilerProviderId, type DecompilerSettings } from "./settings.js";
export interface DecompileInput {
    bytecodeBase64: string;
    builtinAvailable?: boolean;
    builtinSource?: string;
    builtinLatencyMs?: number;
    clientId?: string;
    requestedProvider?: string;
    disabledProviders?: unknown[];
}
export interface DecompileResult {
    ok: boolean;
    source?: string;
    providerId?: DecompilerProviderId;
    attempts: string[];
    attemptedProviders: DecompilerProviderId[];
    error?: string;
    needsBuiltin?: boolean;
}
export interface ResolvedDecompilerProviders {
    orderedProviders: DecompilerProviderId[];
    skippedAttempts: string[];
}
export declare function resolveDecompilerProviders(settings: DecompilerSettings, options?: Pick<DecompileInput, "requestedProvider" | "disabledProviders" | "clientId">): ResolvedDecompilerProviders;
export declare function decompileBytecode(settings: DecompilerSettings, input: DecompileInput): Promise<DecompileResult>;
