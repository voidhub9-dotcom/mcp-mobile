import type { StoredScriptSource } from "../bridge/handlers/shared/script-source-store.js";
export declare const SEMANTIC_DOCUMENT_VERSION = "luau-semantic-card-v2";
export interface EnrichedChunkTemplate {
    embeddingId: string;
    startLine: number;
    endLine: number;
    body: string;
    semanticText: string;
    lexicalText: string;
    chunkType: string;
    label: string;
    summary: string;
    features: string[];
}
export declare function buildSemanticChunkTemplates(script: StoredScriptSource): EnrichedChunkTemplate[];
export declare function tokenizeForSearch(input: string): string[];
export declare function expandQueryTokens(query: string): string[];
