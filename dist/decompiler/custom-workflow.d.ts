export interface CompiledCustomDecompilerWorkflow {
    endpoint: string;
    requestFormat: "template" | "json-script" | "plain-base64" | "plain-bytecode";
    requestField: string;
    requestBodyTemplate?: string;
    requestHeadersTemplate?: string;
    requestVariables?: Array<{
        name: string;
        value: "bytecode" | "base64";
    }>;
    responseFormat: "text" | "json";
    responseField: string;
    apiKeyHeader: string;
    apiKeyPrefix: string;
    headers: Record<string, string>;
}
export declare function compileCustomDecompilerWorkflow(value: unknown): CompiledCustomDecompilerWorkflow | null;
