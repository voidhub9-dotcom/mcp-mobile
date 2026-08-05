export interface StoredScriptSource {
    debugId: string;
    path: string;
    source: string;
    scriptHash?: string;
    sourceHash: string;
    updatedAt: number;
}
export interface ScriptSourceIndex {
    clientId: string;
    placeId: number;
    jobId: string;
    hasFinishedMapping: boolean;
    mappedSources: number;
    processedSources: number;
    skippedSources: number;
    sourcesToMap: number;
    sourceGap: number;
    sourceIndexComplete: boolean;
    scripts: StoredScriptSource[];
}
export type ScriptSourceIndexSummary = Omit<ScriptSourceIndex, "scripts">;
export interface ScriptSourceUpsertResult extends ScriptSourceIndexSummary {
    acceptedMappingRevision?: number;
}
export interface ScriptSourceStoreIdentity {
    clientId: string;
    placeId: number;
    jobId: string;
}
export interface UpsertScriptSourcesInput {
    hasFinishedMapping?: boolean;
    sourcesToMap?: number;
    processedSources?: number;
    skippedSources?: number;
    mappingSessionId?: unknown;
    mappingSessionStartedAt?: unknown;
    mappingRevision?: unknown;
    beginMappingSession?: unknown;
    removedScriptIds?: unknown[];
    scripts?: {
        debugId?: unknown;
        path?: unknown;
        source?: unknown;
        scriptHash?: unknown;
    }[];
}
export interface CachedScriptSourceByHash {
    scriptHash: string;
    debugId: string;
    path: string;
    source: string;
    sourceHash: string;
    updatedAt: number;
}
export declare function upsertScriptSources(identity: ScriptSourceStoreIdentity, input: UpsertScriptSourcesInput): ScriptSourceUpsertResult;
export declare function getCachedScriptSourcesByScriptHash(identity: ScriptSourceStoreIdentity, scriptHashes: unknown[]): CachedScriptSourceByHash[];
export declare function getScriptSourceIndex(identity: ScriptSourceStoreIdentity): ScriptSourceIndex;
export declare function clearScriptSourceIndex(clientId: string): void;
