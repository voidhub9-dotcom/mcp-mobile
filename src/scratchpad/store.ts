export interface ScratchpadEntry {
    key: string;
    value: string;
    createdAt: number;
    updatedAt: number;
    source: string;
}

const store = new Map<string, ScratchpadEntry>();
const MAX_ENTRIES = 500;
const MAX_VALUE_BYTES = 64 * 1024;

export function scratchpadWrite(key: string, value: string, source: string = "mcp"): { ok: boolean; error?: string } {
    if (!key || !/^[\w\-.:@/]+$/.test(key)) {
        return { ok: false, error: "Key must be non-empty and contain only word chars, hyphens, dots, colons, @ or /." };
    }
    if (Buffer.byteLength(value, "utf8") > MAX_VALUE_BYTES) {
        return { ok: false, error: `Value exceeds ${MAX_VALUE_BYTES} byte limit.` };
    }
    if (!store.has(key) && store.size >= MAX_ENTRIES) {
        return { ok: false, error: `Scratchpad full (${MAX_ENTRIES} entry limit). Delete entries first.` };
    }
    const now = Date.now();
    const existing = store.get(key);
    store.set(key, {
        key,
        value,
        source,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
    });
    return { ok: true };
}

export function scratchpadRead(key: string): ScratchpadEntry | undefined {
    return store.get(key);
}

export function scratchpadList(): ScratchpadEntry[] {
    return Array.from(store.values()).sort((a, b) => b.updatedAt - a.updatedAt);
}

export function scratchpadDelete(key: string): boolean {
    return store.delete(key);
}

export function scratchpadClear(): number {
    const count = store.size;
    store.clear();
    return count;
}
