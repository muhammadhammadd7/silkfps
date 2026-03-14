## 0.0.5

* **EventChannel — Real-time Hz stream added**
  * `silkfps/hz_stream` EventChannel fires instantly when OS changes refresh rate
  * `SilkFpsOverlay` badge now shows ACTUAL real-time Hz — no hardcoding needed
  * Removed Timer polling — zero `getCurrentRefreshRate` spam in logs
  * Zero battery waste — event-driven, fires only on Hz change
* **`SilkFpsOverlay` — `setHz` now optional**
  * `setHz: null` (default) → auto real-time Hz from device
  * `setHz: 90` → manual override still supported
* **`SilkfpsPlugin.kt`** — EventChannel stream handler added alongside DisplayListener

## 0.0.4

* **Android — API level strategy added**
  * Minimum supported API: Android 11 (API 30)
  * Android 11-12L (API 30-32) → SKIA strategy
  * Android 13+ (API 33+) → IMPELLER strategy
  * Android 10 and below → skips silently, no crash
* **`SilkDeviceInfo` — new fields**
  * `rendererStrategy` — "SKIA", "IMPELLER", "NOT_SUPPORTED", "Metal"
  * `isHighRefreshRateSupported` — true if Android 11+ or iOS
* **`SilkFps` — new getters**
  * `SilkFps.rendererStrategy`
  * `SilkFps.isHighRefreshRateSupported`
* `initialize()` — silently skips on unsupported devices

## 0.0.3

* **Android — DisplayManager.DisplayListener added**
  * OS refresh rate change → instantly detected → immediately re-applied
  * Zero battery waste — event-driven, no polling loop
  * Works on all devices: 60Hz, 90Hz, 120Hz, 144Hz — auto-detected
* **Android 14+ (API 34)** — `frameRateBoostOnTouchEnabled` added

## 0.0.2

* **Android — Surface.setFrameRate() API added**
  * `preferredDisplayModeId` + `Surface.setFrameRate()` + `frameRateBoostOnTouchEnabled`
* **build.gradle** — Updated `compileSdk` and `targetSdk` to 36, `jvmTarget` to Java 17

## 0.0.1

* Initial release
* Android support — Vulkan auto-detect, high refresh rate
* iOS support — Metal + ProMotion
* Real-time FPS monitor stream
* Live FPS overlay badge
* Battery saver mode
* Adaptive scroll mode
* Lifecycle aware mode
* Per-route FPS control
* FPS analytics (avg, min, max, history)
* SilkDeviceInfo model
* One-line initialize API