import 'package:flutter/services.dart';
import 'package:silkfps/silkfps.dart';
export 'src/silk_device_info.dart';
export 'src/silk_fps_monitor.dart';
export 'src/silk_overlay.dart';
export 'src/silk_adaptive.dart';

/// SilkFPS — Silk smooth FPS boost for Flutter
/// Android 11+ (API 30+) — Skia (API 30-32) + Impeller (API 33+)
/// iOS — Metal + ProMotion
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
  /// Automatically detects device capabilities:
  /// - Android 10 and below → skips (not supported)
  /// - Android 11-12L (API 30-32) → Skia renderer strategy
  /// - Android 13+ (API 33+) → Impeller renderer strategy
  /// - iOS → Metal + ProMotion (automatic)
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

    // Cache device info first — needed for strategy decision
    _cachedDeviceInfo = await getDeviceInfo();

    // Check if device supports high refresh rate
    if (!_cachedDeviceInfo!.isHighRefreshRateSupported) {
      // Android 10 and below — skip silently
      _initialized = true;
      return;
    }

    // Set highest refresh rate based on device strategy
    await setHighRefreshRate();

    // Battery saver
    if (enableBatterySaver) {
      await SilkAdaptive.enableBatterySaver(threshold: batterySaverThreshold);
    }

    _initialized = true;
  }

  // ─────────────────────────────────────────────────────────
  /// Set the highest available refresh rate
  /// Auto-detects: 60Hz, 90Hz, 120Hz, 144Hz
  /// Android 11+ only — iOS handled by system
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
  /// Android 11+ only
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

  // ─────────────────────────────────────────────────────────
  /// Get the renderer strategy for this device
  /// - "NOT_SUPPORTED" — Android 10 and below
  /// - "SKIA"          — Android 11-12L
  /// - "IMPELLER"      — Android 13+
  /// - "Metal"         — iOS
  // ─────────────────────────────────────────────────────────
  static String get rendererStrategy {
    return _cachedDeviceInfo?.rendererStrategy ?? 'UNKNOWN';
  }

  /// Whether this device supports high refresh rate via SilkFPS
  static bool get isHighRefreshRateSupported {
    return _cachedDeviceInfo?.isHighRefreshRateSupported ?? false;
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
