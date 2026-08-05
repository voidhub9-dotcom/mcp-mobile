interface DeepSeekMessage {
    role: "system" | "user" | "assistant" | "tool";
    content?: string | null;
    tool_calls?: Array<{
        id: string;
        type: "function";
        function: {
            name: string;
            arguments: string;
        };
    }>;
    tool_call_id?: string;
}
export interface ChatResult {
    content: string;
    toolCallsMade: Array<{
        name: string;
        args: string;
        result: string;
    }>;
    error?: string;
}
/**
 * Run the DeepSeek + tool-calling agent loop.
 *
 * 1. Get MCP tools in OpenAI format
 * 2. Call DeepSeek chat/completions with messages + tools
 * 3. If the model wants to call tools, execute them and loop
 * 4. Return the final text response
 */
export declare function runAgentLoop(messages: DeepSeekMessage[], apiKeyOverride?: string, modelOverride?: string): Promise<ChatResult>;
export {};
