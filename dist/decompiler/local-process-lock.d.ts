export interface LifetimePaths {
    leases: string;
    providers: string;
}
export declare function withLifetimeLock<T>(paths: LifetimePaths, callback: () => T): T;
