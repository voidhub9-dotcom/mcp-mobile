import type { DecompilerProviderId } from "./settings.js";
type LocalProviderId = Extract<DecompilerProviderId, "shiny" | "fission">;
export interface LocalProviderLaunch {
    provider: LocalProviderId;
    file: string;
    args: string[];
    cwd: string;
    logPath: string;
}
export declare function startManagedLocalProvider(launch: LocalProviderLaunch): void;
export {};
