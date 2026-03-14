## 0.0.3

* **Android — DisplayManager.DisplayListener added (production-grade approach)**
  * OS refresh rate change → instantly detected → immediately re-applied
  * Zero battery waste — event-driven, no polling loop
  * Works on all devices: 60Hz, 90Hz, 120Hz, 144Hz — auto-detected
  * Removed Surface.setFrameRate() monitor loop — replaced with DisplayListener
  * Listener registered on `onAttachedToActivity`, unregistered on `onDetachedFromActivity`
* **Android 14+ (API 34)** — `frameRateBoostOnTouchEnabled` added
* Cleaned up codebase — removed experimental approaches

## 0.0.2

* **Android — Surface.setFrameRate() API added**
  * 3-level refresh rate approach: `preferredDisplayModeId` + `Surface.setFrameRate()` + `frameRateBoostOnTouchEnabled`
  * `Surface.setFrameRate()` (API 30+) bypasses Flutter engine renderer — works on both Vulkan and OpenGLES devices
  * Same approach used by Binance, MEXC, and other production apps
* **build.gradle** — Updated `compileSdk` and `targetSdk` to 36, `jvmTarget` to Java 17
* Fixed refresh rate switching issue on devices with Impeller/OpenGLES renderer (Flutter 3.41+)

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