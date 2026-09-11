export interface ScratchpadEntry {
    key: string;
    value: string;
    createdAt: number;
    updatedAt: number;
    source: string;
}
export declare function scratchpadWrite(key: string, value: string, source?: string): {
    ok: boolean;
    error?: string;
};
export declare function scratchpadRead(key: string): ScratchpadEntry | undefined;
export declare function scratchpadList(): ScratchpadEntry[];
export declare function scratchpadDelete(key: string): boolean;
export declare function scratchpadClear(): number;
