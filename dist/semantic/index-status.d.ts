export interface SemanticIndexStatus {
    chunkCount: number;
    embeddedChunks: number;
    sourceIndexComplete: boolean;
}
export interface ScriptSourceStatus {
    mappedSources: number;
    sourcesToMap: number;
    skippedSources: number;
}
export declare function semanticPartialIndexWarning(status: SemanticIndexStatus): string | undefined;
export declare function semanticIndexReadyMessage(status: SemanticIndexStatus, sources: ScriptSourceStatus): string;
