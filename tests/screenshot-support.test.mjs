import assert from "node:assert/strict";
import test from "node:test";

import { supportsClientScreenshot } from "../dist/bridge/screenshot-capabilities.js";
import { normalizeScreenshotPayload } from "../dist/http/screenshot-payload.js";

test("client screenshot capability recognizes supported executor variants", () => {
  for (const capability of [
    "screenshot",
    "takescreenshot",
    "syn_screenshot",
    "getscreenshot",
    "capturescreen",
    "delta_screenshot",
    "custom_screenshot",
    "screenshot_protocol",
    "client_screenshot",
  ]) {
    assert.equal(supportsClientScreenshot({ [capability]: true }), true, `${capability} should enable client screenshots`);
  }
  assert.equal(supportsClientScreenshot({ screenshot: false, getscreenshot: false }), false);
  assert.equal(supportsClientScreenshot(undefined), false);
});

test("screenshot payload normalization preserves data URIs", () => {
  assert.deepEqual(
    normalizeScreenshotPayload({ imageBase64: "data:image/png;base64,AAAA", mimeType: "image/png" }),
    { imageData: "data:image/png;base64,AAAA", mimeType: "image/png" },
  );
});

test("screenshot payload normalization accepts only HTTPS URLs from trusted upload storage hosts", () => {
  assert.deepEqual(
    normalizeScreenshotPayload({ imageUrl: "https://paste-void.lovable.app/images/test.png", mimeType: "image/jpeg" }),
    { imageData: "https://paste-void.lovable.app/images/test.png", mimeType: "image/jpeg" },
  );
  assert.deepEqual(
    normalizeScreenshotPayload({ imageUrl: "https://project-id.supabase.co/storage/v1/object/public/screenshots/test.png" }),
    { imageData: "https://project-id.supabase.co/storage/v1/object/public/screenshots/test.png", mimeType: "image/png" },
  );
  assert.equal(normalizeScreenshotPayload({ imageUrl: "http://paste-void.lovable.app/image.png" }), null);
  assert.equal(normalizeScreenshotPayload({ imageUrl: "https://example.com/image.png" }), null);
  assert.equal(normalizeScreenshotPayload({ imageUrl: "https://user@paste-void.lovable.app/image.png" }), null);
});
