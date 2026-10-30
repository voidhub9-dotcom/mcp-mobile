const CLIENT_SCREENSHOT_CAPABILITY_KEYS = [
    "client_screenshot",
    "screenshot",
    "takescreenshot",
    "syn_screenshot",
    "getscreenshot",
    "capturescreen",
    "delta_screenshot",
    "custom_screenshot",
    "screenshot_protocol",
] as const;

export function supportsClientScreenshot(capabilities?: Record<string, boolean>): boolean {
    return CLIENT_SCREENSHOT_CAPABILITY_KEYS.some((name) => capabilities?.[name] === true);
}
