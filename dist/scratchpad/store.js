const store = new Map();
const MAX_ENTRIES = 500;
const MAX_VALUE_BYTES = 64 * 1024;
export function scratchpadWrite(key, value, source = "mcp") {
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
export function scratchpadRead(key) {
    return store.get(key);
}
export function scratchpadList() {
    return Array.from(store.values()).sort((a, b) => b.updatedAt - a.updatedAt);
}
export function scratchpadDelete(key) {
    return store.delete(key);
}
export function scratchpadClear() {
    const count = store.size;
    store.clear();
    return count;
}
