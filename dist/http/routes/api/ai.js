import { readJsonBody } from "../../body.js";
import { CUSTOM_AI_API_KEY, CUSTOM_AI_BASE_URL, CUSTOM_AI_API_VERSION, CUSTOM_AI_MODEL, CUSTOM_AI_MAX_TOKENS, CUSTOM_AI_THINKING_ENABLED, CUSTOM_AI_THINKING_BUDGET, } from "../../../config.js";
import { runAgentLoop } from "../../../custom-ai/agent.js";
function jsonOk(res, data) {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(data));
}
function jsonErr(res, error) {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error }));
}
export async function POST(req, res) {
    try {
        const body = await readJsonBody(req);
        const { message, history, config } = body;
        if (!message || typeof message !== "string") {
            return jsonErr(res, "Missing 'message' field.");
        }
        // Build conversation messages in Anthropic format
        const messages = [];
        // Add history
        if (history && Array.isArray(history)) {
            for (const msg of history) {
                if (msg.role === "user" || msg.role === "assistant") {
                    messages.push({ role: msg.role, content: msg.content });
                }
            }
        }
        // Add current message
        messages.push({ role: "user", content: message });
        // Merge config: request overrides > env defaults
        const agentConfig = {
            apiKey: config?.apiKey || CUSTOM_AI_API_KEY || undefined,
            baseUrl: config?.baseUrl || CUSTOM_AI_BASE_URL,
            apiVersion: config?.apiVersion || CUSTOM_AI_API_VERSION,
            model: config?.model || CUSTOM_AI_MODEL,
            maxTokens: config?.maxTokens || CUSTOM_AI_MAX_TOKENS,
            thinkingEnabled: config?.thinkingEnabled ?? CUSTOM_AI_THINKING_ENABLED,
            thinkingBudget: config?.thinkingBudget || CUSTOM_AI_THINKING_BUDGET,
        };
        const result = await runAgentLoop(messages, agentConfig);
        return jsonOk(res, {
            response: result.content,
            thinking: result.thinking,
            toolCalls: result.toolCallsMade,
            ...(result.error ? { error: result.error } : {}),
        });
    }
    catch (err) {
        return jsonErr(res, `AI chat failed: ${err.message || err}`);
    }
}
