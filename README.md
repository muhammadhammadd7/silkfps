# SilkFPS 🎯

[![pub package](https://img.shields.io/pub/v/silkfps.svg)](https://pub.dev/packages/silkfps)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue.svg)](https://pub.dev/packages/silkfps)

**Silk smooth FPS boost for Flutter apps.**  
Auto-detects the highest supported refresh rate on Android (Vulkan/Skia) and iOS (Metal/ProMotion). Includes real-time FPS monitoring, battery saver mode, adaptive scroll mode, per-route FPS control, and a live FPS overlay badge.

---

## 📸 Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/muhammadhammadd7/silkfps/main/assets/images/screenshot_60hz.jpeg" width="45%" alt="SilkFPS — 60Hz" />
  &nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/muhammadhammadd7/silkfps/main/assets/images/screenshot_90hz.jpeg" width="45%" alt="SilkFPS — 90Hz boosted" />
</p>
<p align="center">
  <em>Left: 60Hz (orange badge) &nbsp;|&nbsp; Right: SilkFPS boosted to 90Hz (green badge) ⚡</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/muhammadhammadd7/silkfps/main/assets/images/terminal_output.png" width="90%" alt="adb logcat confirming 90Hz" />
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
| Real-time Hz stream (EventChannel) | ❌ | ✅ |
| Renderer strategy detection | ❌ | ✅ SKIA / IMPELLER |
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
| Android 60Hz (API 30+) | ✅ Auto-detected |
| Android 90Hz (API 30+) | ✅ Auto-detected |
| Android 120Hz (API 30+) | ✅ Auto-detected |
| Android 144Hz (API 30+) | ✅ Auto-detected |
| Android 10 and below (API < 30) | ⚠️ Not supported — skips silently |
| iOS (ProMotion 120Hz) | ✅ Full — Metal + ProMotion |
| iOS (Standard 60Hz) | ✅ 60Hz |

---

## 🔧 How It Works

SilkFPS uses a combination of `preferredDisplayModeId`, `DisplayManager.DisplayListener`, and `EventChannel` for a clean, event-driven architecture:

| Android Version | API | Strategy | Renderer |
|---|---|---|---|
| Android 10 and below | < 30 | Not supported | — |
| Android 11 - 12L | 30 - 32 | SKIA | Skia + Vulkan/OpenGLES |
| Android 13+ | 33+ | IMPELLER | Impeller + Vulkan/OpenGLES |
| iOS | — | Metal | Metal + ProMotion |

**Flow:**
```
App launch → detect API level + max Hz → set preferredDisplayModeId
OS changes Hz → DisplayListener fires → re-apply + push to EventChannel
SilkFpsOverlay → receives Hz via stream → badge updates instantly ✅
```

> Fully event-driven — zero polling, zero battery waste.

---

## 🚀 Quick Start

### 1. Add dependency

```yaml
dependencies:
  silkfps: ^0.0.6
```

### 2. Android — Update `build.gradle.kts`

```kotlin
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
    }
}
```

### 3. Android — Update `MainActivity.kt`

```kotlin
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
    <meta-data
        android:name="io.flutter.embedding.android.EnableVulkan"
        android:value="true" />
    ...
</application>
```

### 5. iOS — Update `Info.plist`

```xml
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

### 6. `main.dart` — Initialize

```dart
import 'package:silkfps/silkfps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SilkFps.initialize(
    showFpsOverlay: true,
    enableBatterySaver: true,
    batterySaverThreshold: 20,
  );

  runApp(const MyApp());
}
```

### 7. Wrap your app — FPS Overlay

```dart
// setHz not needed — auto real-time Hz ✅
SilkFpsOverlay(
  show: SilkFps.showFpsOverlay,
  position: SilkOverlayPosition.topRight,
  child: const MyHomePage(),
)

// Or manual override
SilkFpsOverlay(
  show: SilkFps.showFpsOverlay,
  setHz: 90, // optional
  child: const MyHomePage(),
)
```

---

## 📖 API Reference

### `SilkFps` — Main Class

```dart
await SilkFps.initialize(
  showFpsOverlay: false,
  enableBatterySaver: false,
  batterySaverThreshold: 20,
);

await SilkFps.setHighRefreshRate();
await SilkFps.setRefreshRate(90.0);
double hz = await SilkFps.getCurrentRefreshRate();
List<double> rates = await SilkFps.getSupportedRefreshRates();
bool vulkan = await SilkFps.isVulkanSupported();
int battery = await SilkFps.getBatteryLevel();
SilkDeviceInfo info = await SilkFps.getDeviceInfo();

print(SilkFps.rendererStrategy);           // "SKIA" / "IMPELLER" / "Metal"
print(SilkFps.isHighRefreshRateSupported); // true / false
```

---

### `SilkDeviceInfo` — Device Information

```dart
SilkDeviceInfo info = await SilkFps.getDeviceInfo();

info.manufacturer               // "Google", "Samsung", "Apple"
info.model                      // "Pixel 7a", "S24", "iPhone 15 Pro"
info.osVersion                  // "14", "16", "17.0"
info.apiLevel                   // 36
info.isVulkanSupported          // true
info.isMetalSupported           // false (iOS only)
info.isProMotion                // true if 120Hz+ iPhone
info.maxRefreshRate             // 90.0
info.currentRefreshRate         // 90.0
info.supportedRefreshRates      // [60.0, 90.0]
info.renderer                   // "Vulkan" / "Skia" / "Metal"
info.rendererStrategy           // "SKIA" / "IMPELLER" / "Metal"
info.isHighRefreshRateSupported // true
```

---

### `SilkFpsOverlay` — Live Badge Widget

```dart
SilkFpsOverlay(
  show: true,
  position: SilkOverlayPosition.topRight,
  // setHz optional — null = real-time actual Hz ✅
  child: MyWidget(),
)
```

**Badge colors:**
- 🟢 Green — 90Hz and above
- 🟠 Orange — 60Hz
- 🔴 Red — below 60Hz

**Positions:** `topLeft` | `topRight` | `bottomLeft` | `bottomRight`

---

### `SilkFpsMonitor` — FPS Stream

```dart
SilkFpsMonitor.start(this);
SilkFpsMonitor.fpsStream.listen((fps) => print('FPS: $fps'));
SilkFpsMonitor.stop();
```

---

### `SilkAdaptive` — Smart Management

```dart
await SilkAdaptive.enableBatterySaver(threshold: 20);
await SilkAdaptive.enableAdaptiveMode();
await SilkAdaptive.onScrollStart();
await SilkAdaptive.onScrollEnd();
SilkAdaptive.setFpsForRoute('/home', 90);
SilkAdaptive.setFpsForRoute('/video', 120);
SilkAdaptive.setFpsForRoute('/settings', 60);
```

---

## 🎯 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:silkfps/silkfps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        child: const HomePage(),
      ),
    );
  }
}
```

---

## ⚠️ Known Limitations

- **Android 10 and below** — Not supported. `initialize()` skips silently.
- **iOS** — Custom refresh rate selection not supported. iOS manages ProMotion automatically.
- **Some OEM devices (e.g. Realme ColorOS)** — May drop to 60Hz when app has no active rendering. Rate boosts back immediately on touch/scroll.

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

1. Fork the repo
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📬 Issues

Found a bug? Open an issue on [GitHub](https://github.com/muhammadhammadd7/silkfps/issues).

---

*Made with ❤️ for the Flutter community*