# SilkFPS 🎯

[![pub package](https://img.shields.io/pub/v/silkfps.svg)](https://pub.dev/packages/silkfps)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue.svg)](https://pub.dev/packages/silkfps)

**Silk smooth FPS boost for Flutter apps.**  
Auto-detects the highest supported refresh rate on Android (Vulkan/Skia) and iOS (Metal/ProMotion). Includes real-time FPS monitoring, battery saver mode, adaptive scroll mode, per-route FPS control, and a live FPS overlay badge.

---

## 📸 Screenshots

<p align="center">
  <img src="assets/images/screenshot_60hz.jpeg" width="45%" alt="SilkFPS — 60Hz default" />
  &nbsp;&nbsp;
  <img src="assets/images/screenshot_90hz.jpeg" width="45%" alt="SilkFPS — 90Hz boosted" />
</p>
<p align="center">
  <em>Left: Default 60Hz &nbsp;|&nbsp; Right: SilkFPS boosted to 90Hz ⚡</em>
</p>

<p align="center">
  <img src="assets/images/terminal_output.png" width="90%" alt="adb logcat confirming 90Hz" />
</p>
<p align="center">
  <em>adb logcat confirming <code>appRequestRefreshRateRange=[90 90]</code> — plugin working ✅</em>
</p>

---

## ✨ Features

| Feature | flutter_displaymode | **SilkFPS** |
|---|---|---|
| High refresh rate | ✅ Android only | ✅ Android + iOS |
| Auto device detection | ❌ | ✅ 60/90/120/144Hz |
| DisplayManager.DisplayListener | ❌ | ✅ |
| Vulkan auto-detect | ❌ | ✅ |
| iOS Metal/ProMotion | ❌ | ✅ |
| Real-time FPS stream | ❌ | ✅ |
| Live FPS overlay badge | ❌ | ✅ |
| Battery saver mode | ❌ | ✅ |
| Adaptive scroll mode | ❌ | ✅ |
| Lifecycle aware | ❌ | ✅ |
| Per-route FPS | ❌ | ✅ |
| FPS analytics | ❌ | ✅ |
| Device info | ❌ | ✅ |
| One-line initialize | ❌ | ✅ |

---

## 📱 Platform Support

| Platform | Support |
|---|---|
| Android 60Hz devices | ✅ Auto-detected — stays at 60Hz |
| Android 90Hz devices | ✅ Auto-detected — boosts to 90Hz |
| Android 120Hz devices | ✅ Auto-detected — boosts to 120Hz |
| Android 144Hz devices | ✅ Auto-detected — boosts to 144Hz |
| iOS (ProMotion 120Hz) | ✅ Full — Metal + ProMotion |
| iOS (Standard 60Hz) | ✅ 60Hz |

---

## 🔧 How It Works

SilkFPS uses `preferredDisplayModeId` + `DisplayManager.DisplayListener` for a clean, event-driven approach:

1. **On app start** — detects the device's maximum supported refresh rate automatically
2. **Sets `preferredDisplayModeId`** — tells the OS to use the highest available mode
3. **Registers `DisplayListener`** — monitors for any OS-level rate changes in real time
4. **If OS overrides** — listener fires instantly and re-applies the target rate

```
App launch → detect max rate (60/90/120/144Hz) → set preferredDisplayModeId
OS changes rate → DisplayListener fires instantly → re-apply target rate ✅
```

> This is an event-driven approach — zero polling, zero battery waste. The listener unregisters automatically when the activity detaches.

---

## 🚀 Quick Start

### 1. Add dependency

```yaml
dependencies:
  silkfps: ^0.0.3
```

### 2. Android — Update `build.gradle.kts`

```kotlin
// android/app/build.gradle.kts
android {
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        targetSdk = 36
        // ... rest of your config
    }
}
```

### 3. Android — Update `MainActivity.kt`

> ⚠️ **Important:** This step is required.

```kotlin
// android/app/src/main/kotlin/your/package/MainActivity.kt
package your.package.name

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setOptimalRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        setOptimalRefreshRate()
    }

    private fun setOptimalRefreshRate() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val display = windowManager.defaultDisplay
                val currentMode = display.mode
                display.supportedModes
                    .filter {
                        it.physicalWidth == currentMode.physicalWidth &&
                        it.physicalHeight == currentMode.physicalHeight
                    }
                    .maxByOrNull { it.refreshRate }
                    ?.let {
                        val params = window.attributes
                        params.preferredDisplayModeId = it.modeId
                        window.attributes = params
                    }
            }
            if (android.os.Build.VERSION.SDK_INT >= 34) {
                window.frameRateBoostOnTouchEnabled = true
            }
        } catch (e: Exception) {
            android.util.Log.e("SilkFPS", "Error: ${e.message}")
        }
    }
}
```

### 4. Android — Update `AndroidManifest.xml`

```xml
<application ...>
    <!-- SilkFPS — Vulkan on supported devices, Skia fallback on others -->
    <meta-data
        android:name="io.flutter.embedding.android.EnableVulkan"
        android:value="true" />
    ...
</application>
```

### 5. iOS — Update `Info.plist`

```xml
<!-- Enable ProMotion 120fps on iPhone 13 Pro and above -->
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

### 6. `main.dart` — Initialize

```dart
import 'package:silkfps/silkfps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ One line — everything is automatic!
  await SilkFps.initialize(
    showFpsOverlay: true,       // Live FPS badge in the corner
    enableBatterySaver: true,   // Auto switch to 60fps on low battery
    batterySaverThreshold: 20,  // Switch at 20% battery
  );

  runApp(const MyApp());
}
```

### 7. Wrap your app — FPS Overlay

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SilkFpsOverlay(
        show: SilkFps.showFpsOverlay,
        position: SilkOverlayPosition.topRight,
        setHz: 90,
        child: const MyHomePage(),
      ),
    );
  }
}
```

---

## 📖 API Reference

### `SilkFps` — Main Class

```dart
// Initialize — call once in main()
await SilkFps.initialize(
  showFpsOverlay: false,
  enableBatterySaver: false,
  batterySaverThreshold: 20,
);

// Set the highest available refresh rate
await SilkFps.setHighRefreshRate();

// Set a specific refresh rate
await SilkFps.setRefreshRate(90.0);

// Get the current refresh rate
double hz = await SilkFps.getCurrentRefreshRate();

// Get all supported refresh rates
List<double> rates = await SilkFps.getSupportedRefreshRates();
// Returns: [45.0, 60.0, 90.0]

// Check Vulkan support (Android only)
bool vulkan = await SilkFps.isVulkanSupported();

// Get battery level
int battery = await SilkFps.getBatteryLevel();

// Get device info
SilkDeviceInfo info = await SilkFps.getDeviceInfo();
print(info.manufacturer);           // realme
print(info.model);                  // RMX2001
print(info.renderer);               // Vulkan / Skia / Metal
print(info.maxRefreshRate);         // 90.0
print(info.isProMotion);            // false
print(info.supportedRefreshRates);  // [45.0, 60.0, 90.0]
```

---

### `SilkFpsMonitor` — Real-time FPS Stream

```dart
class MyWidget extends StatefulWidget { ... }

class _MyWidgetState extends State<MyWidget>
    with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    SilkFpsMonitor.start(this);
    SilkFpsMonitor.fpsStream.listen((fps) {
      print('Live FPS: $fps');
    });
  }

  @override
  void dispose() {
    SilkFpsMonitor.stop();
    super.dispose();
  }
}
```

---

### `SilkFpsOverlay` — Live FPS Badge Widget

```dart
SilkFpsOverlay(
  show: true,
  position: SilkOverlayPosition.topRight,
  setHz: 90,
  child: MyWidget(),
)
```

**Available Positions:**
- `SilkOverlayPosition.topLeft`
- `SilkOverlayPosition.topRight`
- `SilkOverlayPosition.bottomLeft`
- `SilkOverlayPosition.bottomRight`

---

### `SilkAdaptive` — Smart FPS Management

```dart
// Battery Saver — auto switch to 60fps on low battery
await SilkAdaptive.enableBatterySaver(threshold: 20);
SilkAdaptive.disableBatterySaver();

// Adaptive Scroll — high FPS while scrolling, low FPS when idle
await SilkAdaptive.enableAdaptiveMode();
await SilkAdaptive.onScrollStart();
await SilkAdaptive.onScrollEnd();
SilkAdaptive.disableAdaptiveMode();

// Lifecycle Aware — 60fps in background, 90fps in foreground
SilkAdaptive.enableLifecycleAware(context);
SilkAdaptive.disableLifecycleAware();

// Per-Route FPS — different FPS for different screens
SilkAdaptive.setFpsForRoute('/home', 90);
SilkAdaptive.setFpsForRoute('/video', 120);
SilkAdaptive.setFpsForRoute('/settings', 60);

// Analytics
SilkAdaptive.recordFps(fps);
double avg = SilkAdaptive.getAverageFps();
double min = SilkAdaptive.getMinFps();
double max = SilkAdaptive.getMaxFps();
List<double> history = SilkAdaptive.getFpsHistory();
SilkAdaptive.clearHistory();
```

---

### `SilkDeviceInfo` — Device Information Model

```dart
SilkDeviceInfo info = await SilkFps.getDeviceInfo();

info.manufacturer           // "realme", "Samsung", "Apple"
info.model                  // "RMX2001", "S24", "iPhone 15 Pro"
info.osVersion              // "11", "14", "17.0"
info.apiLevel               // 30 (Android only)
info.isVulkanSupported      // true/false (Android)
info.isMetalSupported       // true/false (iOS)
info.isProMotion            // true if 120Hz+ (iPhone 13 Pro+)
info.maxRefreshRate         // 90.0, 120.0, 144.0
info.currentRefreshRate     // Current Hz
info.supportedRefreshRates  // [60.0, 90.0]
info.renderer               // "Vulkan", "Skia", "Metal"
```

---

## 🎯 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:silkfps/silkfps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SilkAdaptive.setFpsForRoute('/home', 90);
  SilkAdaptive.setFpsForRoute('/settings', 60);

  await SilkFps.initialize(
    showFpsOverlay: true,
    enableBatterySaver: true,
    batterySaverThreshold: 20,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SilkFpsOverlay(
        show: SilkFps.showFpsOverlay,
        position: SilkOverlayPosition.topRight,
        setHz: 90,
        child: const HomePage(),
      ),
    );
  }
}
```

---

## ⚠️ Known Limitations

- **iOS** — Custom refresh rate selection is not supported. iOS automatically manages ProMotion.
- **Android idle behavior** — Some OEM devices (e.g. Realme ColorOS) may drop to 60Hz when the app has no active rendering. This is OS-level adaptive behavior — the rate boosts back immediately on touch/scroll interaction.
- **Comparison with `flutter_displaymode`** — Unlike `flutter_displaymode` which is Android-only and uses a single API call, SilkFPS supports both platforms, uses `DisplayManager.DisplayListener` for OS override detection, and includes additional features like FPS monitoring, battery saver, and adaptive scroll.

---

## 📄 License

```
MIT License

Copyright (c) 2026 Muhammad Hammad

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📬 Issues

Found a bug? Please open an issue on [GitHub](https://github.com/muhammadhammad7/silkfps/issues).

---

*Made with ❤️ for the Flutter community*