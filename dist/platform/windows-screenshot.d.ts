export interface RobloxWindowInfo {
    pid: number;
    hwnd: string;
    title: string;
}
export interface ScreenshotResult {
    error?: string;
    needsDisambiguation?: boolean;
    windows?: RobloxWindowInfo[];
    imageBase64?: string;
    mimeType?: string;
}
export declare const DEFAULT_SCREENSHOT_MAX_WIDTH = 1280;
export declare const DEFAULT_SCREENSHOT_JPEG_QUALITY = 70;
export declare function isSupported(): boolean;
export declare function enumRobloxWindows(): RobloxWindowInfo[];
export declare function performScreenshot(pid?: number, maxWidth?: number): ScreenshotResult;
