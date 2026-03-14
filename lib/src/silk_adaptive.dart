import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SilkAdaptive — Smart FPS management
class SilkAdaptive {
  static const MethodChannel _channel = MethodChannel('silkfps');

  static bool _batterySaverEnabled = false;
  static int _batterySaverThreshold = 20;
  static bool _adaptiveModeEnabled = false;
  static Timer? _batteryCheckTimer;
  static final List<double> _fpsHistory = [];
  static final Map<String, double> _routeFpsMap = {};

  // ─────────────────────────────────────────────────────────
  /// Battery Saver Mode
  // ─────────────────────────────────────────────────────────
  static Future<void> enableBatterySaver({int threshold = 20}) async {
    _batterySaverEnabled = true;
    _batterySaverThreshold = threshold;
    _batteryCheckTimer?.cancel();
    _batteryCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkBattery(),
    );
    await _checkBattery();
  }

  static void disableBatterySaver() {
    _batterySaverEnabled = false;
    _batteryCheckTimer?.cancel();
  }

  static Future<void> _checkBattery() async {
    if (!_batterySaverEnabled) return;
    try {
      final battery =
          await _channel.invokeMethod<int>('getBatteryLevel') ?? 100;
      if (battery <= _batterySaverThreshold) {
        await _channel.invokeMethod('setRefreshRate', {'rate': 60.0});
      } else {
        await _channel.invokeMethod('setHighRefreshRate');
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────
  /// Adaptive Mode — High FPS while scrolling, low FPS when idle
  // ─────────────────────────────────────────────────────────
  static Future<void> enableAdaptiveMode() async {
    _adaptiveModeEnabled = true;
    await _channel.invokeMethod('setHighRefreshRate');
  }

  static void disableAdaptiveMode() => _adaptiveModeEnabled = false;

  static Future<void> onScrollStart() async {
    if (!_adaptiveModeEnabled) return;
    await _channel.invokeMethod('setHighRefreshRate');
  }

  static Future<void> onScrollEnd() async {
    if (!_adaptiveModeEnabled) return;
    await _channel.invokeMethod('setRefreshRate', {'rate': 60.0});
  }

  // ─────────────────────────────────────────────────────────
  /// Lifecycle Aware
  // ─────────────────────────────────────────────────────────
  static void enableLifecycleAware(BuildContext context) {
    WidgetsBinding.instance.addObserver(_SilkLifecycleObserver());
  }

  static void disableLifecycleAware() {}

  // ─────────────────────────────────────────────────────────
  /// Per Route FPS
  // ─────────────────────────────────────────────────────────
  static void setFpsForRoute(String routeName, double fps) {
    _routeFpsMap[routeName] = fps;
  }

  static Future<void> applyRoutefps(String routeName) async {
    final fps = _routeFpsMap[routeName];
    if (fps != null) {
      await _channel.invokeMethod('setRefreshRate', {'rate': fps});
    }
  }

  static SilkRouteObserver get routeObserver => SilkRouteObserver();

  // ─────────────────────────────────────────────────────────
  /// Analytics
  // ─────────────────────────────────────────────────────────
  static void recordFps(double fps) {
    _fpsHistory.add(fps);
    if (_fpsHistory.length > 1000) _fpsHistory.removeAt(0);
  }

  static List<double> getFpsHistory() => List.unmodifiable(_fpsHistory);

  static double getAverageFps() {
    if (_fpsHistory.isEmpty) return 0;
    return _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  }

  static double getMinFps() =>
      _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce((a, b) => a < b ? a : b);

  static double getMaxFps() =>
      _fpsHistory.isEmpty ? 0 : _fpsHistory.reduce((a, b) => a > b ? a : b);

  static void clearHistory() => _fpsHistory.clear();

  static void dispose() {
    _batteryCheckTimer?.cancel();
    _batterySaverEnabled = false;
    _adaptiveModeEnabled = false;
  }
}

class _SilkLifecycleObserver extends WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('silkfps');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _channel.invokeMethod('setHighRefreshRate');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _channel.invokeMethod('setRefreshRate', {'rate': 60.0});
        break;
      default:
        break;
    }
  }
}

class SilkRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      SilkAdaptive.applyRoutefps(route.settings.name!);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      SilkAdaptive.applyRoutefps(previousRoute!.settings.name!);
    }
  }
}
