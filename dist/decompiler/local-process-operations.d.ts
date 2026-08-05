export interface ProcessSnapshot {
    commandLine: string;
    startToken: string;
}
export interface ProcessOperations {
    snapshot(pid: number): ProcessSnapshot | null;
    terminate(pid: number, force: boolean): void;
    wait(milliseconds: number): void;
}
export declare function processIsAlive(pid: number): boolean;
export declare function blockingWait(milliseconds: number): void;
export declare function commandContainsToken(commandLine: string, commandToken: string): boolean;
export declare function processSnapshotMatches(expected: {
    commandToken: string;
    startToken: string;
}, snapshot: ProcessSnapshot | null): boolean;
export declare const localProcessOperations: ProcessOperations;
