interface ContentBlock {
    type: "text" | "tool_use" | "thinking";
    text?: string;
    id?: string;
    name?: string;
    input?: Record<string, unknown>;
    thinking?: string;
}
interface AnthropicMessage {
    role: "user" | "assistant";
    content: string | ContentBlock[];
}
export interface ToolCallInfo {
    name: string;
    input: string;
    result: string;
}
export interface ThinkingBlock {
    text: string;
}
export interface ChatResult {
    content: string;
    thinking: ThinkingBlock[];
    toolCallsMade: ToolCallInfo[];
    error?: string;
}
export interface AgentConfig {
    apiKey?: string;
    baseUrl?: string;
    apiVersion?: string;
    model?: string;
    maxTokens?: number;
    thinkingEnabled?: boolean;
    thinkingBudget?: number;
}
/**
 * Run the Anthropic-compatible agent loop.
 *
 * 1. Get MCP tools in Anthropic format
 * 2. Call the Messages API with messages + tools
 * 3. If the model returns tool_use blocks, execute them and loop
 * 4. Return final text + any thinking blocks + tool call info
 */
export declare function runAgentLoop(messages: AnthropicMessage[], config?: AgentConfig): Promise<ChatResult>;
export {};
