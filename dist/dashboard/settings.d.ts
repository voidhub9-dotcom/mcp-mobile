export declare const DASHBOARD_THEME_IDS: readonly ["default", "claude", "chatgpt", "github-dark", "github-light", "custom"];
export declare const DASHBOARD_SANS_FONT_IDS: readonly ["geist", "ibm-plex", "source-sans", "system", "custom"];
export declare const DASHBOARD_MONO_FONT_IDS: readonly ["geist-mono", "ibm-plex-mono", "jetbrains-mono", "system-mono", "custom"];
export type DashboardThemeId = (typeof DASHBOARD_THEME_IDS)[number];
export type DashboardSansFontId = (typeof DASHBOARD_SANS_FONT_IDS)[number];
export type DashboardMonoFontId = (typeof DASHBOARD_MONO_FONT_IDS)[number];
export interface DashboardThemeColors {
    background: string;
    surface: string;
    raised: string;
    border: string;
    accent: string;
    text: string;
    muted: string;
}
export interface DashboardThemeFonts {
    sans: DashboardSansFontId;
    mono: DashboardMonoFontId;
    customSans: string;
    customMono: string;
}
export interface DashboardBackgroundMedia {
    type: "none" | "image" | "video";
    url: string;
    fit: "cover" | "contain";
    opacity: number;
}
export interface DashboardSettings {
    version: 1;
    theme: DashboardThemeId;
    colors: DashboardThemeColors;
    fonts: DashboardThemeFonts;
    backgroundMedia: DashboardBackgroundMedia;
}
export type DashboardSettingsInput = Partial<{
    version: unknown;
    theme: unknown;
    colors: unknown;
    fonts: unknown;
    backgroundMedia: unknown;
}>;
export declare const DASHBOARD_CONFIG_DIR: string;
export declare const DASHBOARD_SETTINGS_PATH: string;
export declare const DEFAULT_DASHBOARD_SETTINGS: DashboardSettings;
export declare function normalizeDashboardSettings(value: unknown, fallback?: DashboardSettings): DashboardSettings;
export declare function dashboardSettingsExist(): Promise<boolean>;
export declare function loadDashboardSettings(): Promise<DashboardSettings>;
export declare function saveDashboardSettings(input: DashboardSettingsInput): Promise<DashboardSettings>;
