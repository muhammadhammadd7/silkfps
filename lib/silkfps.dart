import 'package:flutter/services.dart';
import 'package:silkfps/silkfps.dart';
export 'src/silk_device_info.dart';
export 'src/silk_fps_monitor.dart';
export 'src/silk_overlay.dart';
export 'src/silk_adaptive.dart';

/// SilkFPS — Silk smooth FPS boost for Flutter
/// Android (Vulkan/Skia) + iOS (Metal/ProMotion)
///
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// QUICK START:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await SilkFps.initialize(showFpsOverlay: true);
///   runApp(const MyApp());
/// }
///
/// // Wrap your app
/// home: SilkFpsOverlay(
///   show: SilkFps.showFpsOverlay,
///   child: MyHomePage(),
/// )
/// ```
class SilkFps {
  static const MethodChannel _channel = MethodChannel('silkfps');

  static bool _initialized = false;
  static bool _showFpsOverlay = false;
  static SilkDeviceInfo? _cachedDeviceInfo;

  static bool get showFpsOverlay => _showFpsOverlay;
  static bool get isInitialized => _initialized;

  // ─────────────────────────────────────────────────────────
  /// ONE TIME INITIALIZE — call once in main()
  ///
  /// [showFpsOverlay] — Live Hz + FPS badge in the corner
  /// [enableBatterySaver] — Auto switch to 60fps on low battery
  /// [batterySaverThreshold] — Battery % threshold (default 20)
  // ─────────────────────────────────────────────────────────
  static Future<void> initialize({
    bool showFpsOverlay = false,
    bool enableBatterySaver = false,
    int batterySaverThreshold = 20,
  }) async {
    if (_initialized) return;

    _showFpsOverlay = showFpsOverlay;

    // Set the highest available refresh rate
    await setHighRefreshRate();

    // Battery saver
    if (enableBatterySaver) {
      await SilkAdaptive.enableBatterySaver(threshold: batterySaverThreshold);
    }

    // Cache device info
    _cachedDeviceInfo = await getDeviceInfo();

    _initialized = true;
  }

  // ─────────────────────────────────────────────────────────
  /// Set the highest available refresh rate
  /// Android: 90/120/144 Hz auto detect
  /// iOS: Metal + ProMotion
  // ─────────────────────────────────────────────────────────
  static Future<bool> setHighRefreshRate() async {
    try {
      return await _channel.invokeMethod<bool>('setHighRefreshRate') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  /// Set a custom refresh rate
  /// [rate] — in Hz (45, 60, 90, 120, 144)
  // ─────────────────────────────────────────────────────────
  static Future<bool> setRefreshRate(double rate) async {
    try {
      return await _channel.invokeMethod<bool>('setRefreshRate', {
            'rate': rate,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  /// Get the current refresh rate
  // ─────────────────────────────────────────────────────────
  static Future<double> getCurrentRefreshRate() async {
    try {
      return await _channel.invokeMethod<double>('getCurrentRefreshRate') ??
          60.0;
    } catch (_) {
      return 60.0;
    }
  }

  // ─────────────────────────────────────────────────────────
  /// Get all supported refresh rates
  /// Example: [45.0, 60.0, 90.0]
  // ─────────────────────────────────────────────────────────
  static Future<List<double>> getSupportedRefreshRates() async {
    try {
      final result = await _channel.invokeMethod<List>(
        'getSupportedRefreshRates',
      );
      return result?.map((e) => (e as num).toDouble()).toList() ?? [60.0];
    } catch (_) {
      return [60.0];
    }
  }

  // ─────────────────────────────────────────────────────────
  /// Check Vulkan support
  /// Android only — always returns false on iOS
  // ─────────────────────────────────────────────────────────
  static Future<bool> isVulkanSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isVulkanSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  /// Get battery level (0-100)
  // ─────────────────────────────────────────────────────────
  static Future<int> getBatteryLevel() async {
    try {
      return await _channel.invokeMethod<int>('getBatteryLevel') ?? 100;
    } catch (_) {
      return 100;
    }
  }

  // ─────────────────────────────────────────────────────────
  /// Get complete device info
  /// Cached after initialize()
  // ─────────────────────────────────────────────────────────
  static Future<SilkDeviceInfo> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) return _cachedDeviceInfo!;
    try {
      final result = await _channel.invokeMethod<Map>('getDeviceInfo');
      return SilkDeviceInfo.fromMap(Map<String, dynamic>.from(result ?? {}));
    } catch (_) {
      return SilkDeviceInfo.fromMap({});
    }
  }
}

/// Backward compatibility
@Deprecated('Use SilkFps instead')
class Silkfps {
  static Future<bool> setHighRefreshRate() => SilkFps.setHighRefreshRate();
  static Future<bool> setRefreshRate(double rate) =>
      SilkFps.setRefreshRate(rate);
  static Future<double> getCurrentRefreshRate() =>
      SilkFps.getCurrentRefreshRate();
  static Future<List<double>> getSupportedRefreshRates() =>
      SilkFps.getSupportedRefreshRates();
  static Future<bool> isVulkanSupported() => SilkFps.isVulkanSupported();
  static Future<int> getBatteryLevel() => SilkFps.getBatteryLevel();
  static Future<SilkDeviceInfo> getDeviceInfo() => SilkFps.getDeviceInfo();
}
