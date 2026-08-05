import { type TrackedProcess } from "./local-process-lifetime.js";
export declare function watchLocalDecompilerProcess(options: {
    tracked: TrackedProcess;
    recordPath: string;
    leaseDirectory: string;
}): Promise<void>;
