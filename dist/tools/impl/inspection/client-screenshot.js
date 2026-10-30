import { z } from "zod";
import { normalizeScreenshotPayload } from "../../../http/screenshot-payload.js";
import { sendAndWait } from "../../factory.js";
import { maxOutputCharsSchema } from "../../schemas.js";
function parseImageFromText(text) {
    const patterns = [
        /data:image\/([a-z]+);base64,([A-Za-z0-9+/=]+)/,
        /"imageBase64":\s*"data:image\/([a-z]+);base64,([A-Za-z0-9+/=]+)/,
        /"imageBase64":\s*"([A-Za-z0-9+/=]+)"/,
    ];
    for (const pattern of patterns) {
        const match = text.match(pattern);
        if (match) {
            if (match[2] && match[1]) {
                return { data: match[2], mimeType: `image/${match[1]}` };
            }
            if (match[1] && match[1].length > 100 && /^[A-Za-z0-9+/=]+$/.test(match[1])) {
                return { data: match[1], mimeType: "image/png" };
            }
        }
    }
    return null;
}
function parseCaptureError(text) {
    try {
        const payload = JSON.parse(text);
        if (payload.success === false || typeof payload.error === "string") {
            return typeof payload.error === "string" ? payload.error : "Client screenshot capture failed.";
        }
    }
    catch {
    }
    return null;
}
export default function register(server) {
    server.registerTool("client-screenshot", {
        title: "Take a screenshot from the Roblox client (cross-platform)",
        description: "Capture a screenshot from the connected Roblox client using in-game viewport capture. Works on any platform (Windows, Mac, mobile). The AI receives the actual image and can visually analyze the game screen. The executor must expose screenshot(), takescreenshot(), syn.screenshot(), getscreenshot(), capturescreen(), delta_screenshot(), a configured MCP_ScreenshotFn, or screenshot:// support.",
        inputSchema: z.object({
            maxWidth: z
                .number()
                .describe("Maximum image width in pixels (default: 1280). Lower values cost fewer vision tokens.")
                .optional()
                .default(1280),
            quality: z
                .number()
                .describe("JPEG/PNG quality percentage (default: 80, range 20-100).")
                .optional()
                .default(80),
            maxOutputChars: maxOutputCharsSchema,
        }),
    }, async ({ maxWidth, quality, maxOutputChars }) => {
        const result = await sendAndWait({
            type: "client-screenshot",
            data: { maxWidth, quality },
            maxOutputChars: 32000,
            stampClient: true,
            failureMessage: () => "Failed to capture client screenshot. The connected executor may not support in-game screenshot capture.",
        });
        if (result.isError) {
            return result;
        }
        const text = result.content
            ?.filter((c) => c.type === "text")
            .map((c) => c.text)
            .join("");
        // Handle URL-based response (connector uploaded to paste-void)
        if (text) {
            try {
                const payload = JSON.parse(text);
                if (payload.imageUrl) {
                    const normalized = normalizeScreenshotPayload(payload);
                    if (!normalized || !normalized.imageData.startsWith("https://")) {
                        return {
                            content: [{ type: "text", text: "The screenshot connector returned an unsupported image URL." }],
                            isError: true,
                        };
                    }
                    const imgRes = await fetch(normalized.imageData);
                    if (imgRes.ok) {
                        const buf = await imgRes.arrayBuffer();
                        const b64 = Buffer.from(buf).toString("base64");
                        return {
                            content: [
                                { type: "text", text: `Screenshot captured and hosted at ${normalized.imageData}` },
                                { type: "image", data: b64, mimeType: normalized.mimeType },
                            ],
                        };
                    }
                    // URL fetch failed — return the URL as text so Claude at least has it
                    return {
                        content: [{ type: "text", text: `Screenshot URL: ${normalized.imageData}` }],
                    };
                }
            }
            catch {
                // Not a JSON imageUrl response, fall through
            }
        }
        const image = text ? parseImageFromText(text) : null;
        if (image) {
            const content = [
                { type: "text", text: "In-game screenshot captured." },
                { type: "image", data: image.data, mimeType: image.mimeType },
            ];
            return { content };
        }
        const captureError = text ? parseCaptureError(text) : null;
        if (captureError) {
            return {
                content: [{ type: "text", text: captureError }],
                isError: true,
            };
        }
        return result;
    });
}
