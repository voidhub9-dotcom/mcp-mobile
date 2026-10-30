export interface ScreenshotCapturePayload {
    imageBase64?: unknown;
    imageUrl?: unknown;
    mimeType?: unknown;
}

export interface NormalizedScreenshotPayload {
    imageData: string;
    mimeType: string;
}

function normalizeMimeType(value: unknown): string {
    return typeof value === "string" && /^image\/[a-z0-9.+-]+$/i.test(value)
        ? value
        : "image/png";
}

export function normalizeScreenshotPayload(capture: ScreenshotCapturePayload): NormalizedScreenshotPayload | null {
    const mimeType = normalizeMimeType(capture.mimeType);
    if (typeof capture.imageBase64 === "string" && capture.imageBase64.startsWith("data:image/")) {
        return { imageData: capture.imageBase64, mimeType };
    }

    if (typeof capture.imageUrl !== "string") return null;
    try {
        const url = new URL(capture.imageUrl);
        const trustedHost = url.hostname === "paste-void.lovable.app" || url.hostname.endsWith(".supabase.co");
        if (url.protocol !== "https:" || !trustedHost || url.port || url.username || url.password) {
            return null;
        }
        return { imageData: url.toString(), mimeType };
    } catch {
        return null;
    }
}
