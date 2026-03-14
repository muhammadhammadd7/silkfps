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
  * `SilkFps.rendererStrategy` — current device strategy
  * `SilkFps.isHighRefreshRateSupported` — quick support check
* `initialize()` — silently skips on unsupported devices (no error)

## 0.0.3

* **Android — DisplayManager.DisplayListener added (production-grade approach)**
  * OS refresh rate change → instantly detected → immediately re-applied
  * Zero battery waste — event-driven, no polling loop
  * Works on all devices: 60Hz, 90Hz, 120Hz, 144Hz — auto-detected
  * Listener registered on `onAttachedToActivity`, unregistered on `onDetachedFromActivity`
* **Android 14+ (API 34)** — `frameRateBoostOnTouchEnabled` added
* Cleaned up codebase — removed experimental approaches

## 0.0.2

* **Android — Surface.setFrameRate() API added**
  * 3-level refresh rate approach: `preferredDisplayModeId` + `Surface.setFrameRate()` + `frameRateBoostOnTouchEnabled`
  * `Surface.setFrameRate()` (API 30+) bypasses Flutter engine renderer — works on both Vulkan and OpenGLES devices
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