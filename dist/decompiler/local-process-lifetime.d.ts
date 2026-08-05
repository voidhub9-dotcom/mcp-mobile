import { type ProcessOperations, type ProcessSnapshot } from "./local-process-operations.js";
import { type LifetimePaths } from "./local-process-lock.js";
import { type DecompilerProviderId } from "./settings.js";
type LocalProviderId = Extract<DecompilerProviderId, "shiny" | "fission">;
export interface TrackedProcess extends ProcessSnapshot {
    pid: number;
    commandToken: string;
}
export interface TerminationPolicy {
    zeroLeaseGraceMs: number;
    registrationIntentQuietMs: number;
    graceMs: number;
    forceWaitMs: number;
    pollMs: number;
}
export interface WatchdogHandle {
    once(event: "error", listener: (error: Error) => void): WatchdogHandle;
    once(event: "exit", listener: (code: number | null, signal: NodeJS.Signals | null) => void): WatchdogHandle;
    removeListener(event: "exit", listener: (code: number | null, signal: NodeJS.Signals | null) => void): WatchdogHandle;
    unref(): void;
}
export type WatchdogStarter = (args: string[]) => WatchdogHandle;
export declare const LOCAL_PROCESS_LIFETIME_PATHS: LifetimePaths;
export declare const DEFAULT_TERMINATION_POLICY: TerminationPolicy;
export declare function registrationIntentDirectory(paths: LifetimePaths): string;
export declare function publishTrackedProcess(directory: string, tracked: TrackedProcess): string;
export declare function acquireProcessLease(pid: number, commandToken: string, paths?: LifetimePaths, operations?: ProcessOperations): boolean;
declare function readTrackedProcesses(directory: string, operations: ProcessOperations): Array<TrackedProcess & {
    file: string;
}>;
export declare function terminateTrackedProcess(tracked: TrackedProcess, operations?: ProcessOperations, policy?: TerminationPolicy, shouldCancel?: () => boolean): boolean;
export declare function releaseProcessLease(pid: number, paths?: LifetimePaths, operations?: ProcessOperations, terminationPolicy?: TerminationPolicy): number;
export declare function shutdownManagedProvidersIfNoLeases(paths?: LifetimePaths, operations?: ProcessOperations, terminationPolicy?: TerminationPolicy): number;
export declare function registerLocalDecompilerLifetime(): void;
export declare function trackLocalDecompilerProcess(provider: LocalProviderId, pid: number, binaryPath: string, options?: {
    paths?: LifetimePaths;
    operations?: ProcessOperations;
    startWatchdog?: WatchdogStarter;
    terminationPolicy?: TerminationPolicy;
    publishTracked?: typeof publishTrackedProcess;
}): boolean;
export declare const readLiveTrackedProcesses: typeof readTrackedProcesses;
export { localProcessOperations } from "./local-process-operations.js";
export type { ProcessOperations, ProcessSnapshot } from "./local-process-operations.js";
export type { LifetimePaths } from "./local-process-lock.js";
