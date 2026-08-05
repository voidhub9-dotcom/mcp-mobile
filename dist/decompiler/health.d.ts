import { type DecompilerProviderId, type DecompilerRuntimeSettings } from "./settings.js";
export type DecompilerProviderHealthStatus = "healthy" | "slow" | "cooling_down" | "rate_limited" | "timing_out" | "unknown";
export interface DecompilerProviderHealthReport {
    id: DecompilerProviderId;
    status: DecompilerProviderHealthStatus;
    latencyMs?: number;
    throughputPerSecond?: number;
    throughputWindowMs?: number;
    throughputSamples?: number;
    slowCount?: number;
    timeoutCount?: number;
    lastError?: string;
    cooldownRemainingMs?: number;
    rateLimitedRemainingMs?: number;
}
export interface DecompilerProviderHealthSnapshot extends Omit<DecompilerProviderHealthReport, "cooldownRemainingMs" | "rateLimitedRemainingMs"> {
    clientId: string;
    updatedAt: string;
    cooldownUntil?: string;
    rateLimitedUntil?: string;
}
export declare function reportDecompilerHealth(clientId: string, providers: unknown, allowedProviderIds?: ReadonlySet<string>): void;
export declare function shouldSkipDecompilerProvider(id: DecompilerProviderId, runtime: DecompilerRuntimeSettings, clientId?: string): {
    skip: boolean;
    reason?: string;
};
export declare function getDecompilerProviderStatus(id: DecompilerProviderId, clientId?: string): DecompilerProviderHealthStatus;
export declare function recordDecompilerProviderObservation(options: {
    id: DecompilerProviderId;
    runtime: DecompilerRuntimeSettings;
    clientId?: string;
    latencyMs?: number;
    successCount?: number;
    throughputPerSecond?: number;
    throughputWindowMs?: number;
    throughputSamples?: number;
    errorMessage?: string;
    timedOut?: boolean;
    observationSessionId?: string;
    observationSessionStartedAt?: number;
    observationRevision?: number;
    beginObservationSession?: boolean;
}): boolean;
export declare function recordDecompilerProviderSuccess(id: DecompilerProviderId, latencyMs: number, runtime: DecompilerRuntimeSettings, clientId?: string): void;
export declare function recordDecompilerProviderFailure(options: {
    id: DecompilerProviderId;
    errorMessage: string;
    runtime: DecompilerRuntimeSettings;
    statusCode?: number;
    timedOut?: boolean;
    latencyMs?: number;
    clientId?: string;
}): void;
export declare function clearDecompilerHealthForClient(clientId: string): void;
export declare function getDecompilerHealthSnapshot(clientId?: string): {
    providers: Partial<Record<DecompilerProviderId, DecompilerProviderHealthSnapshot>>;
};
