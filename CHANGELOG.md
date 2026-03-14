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