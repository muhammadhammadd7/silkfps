import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Real-time FPS monitor
class SilkFpsMonitor {
  static Ticker? _ticker;
  static final StreamController<double> _controller =
      StreamController<double>.broadcast();

  static int _frameCount = 0;
  static int _lastTimestamp = 0;
  static double _currentFps = 0;

  static Stream<double> get fpsStream => _controller.stream;
  static double get currentFps => _currentFps;

  static void start(TickerProvider vsync) {
    stop();
    _lastTimestamp = DateTime.now().millisecondsSinceEpoch;
    _frameCount = 0;

    _ticker = vsync.createTicker((elapsed) {
      _frameCount++;
      final now = DateTime.now().millisecondsSinceEpoch;
      final delta = now - _lastTimestamp;

      if (delta >= 1000) {
        _currentFps = (_frameCount * 1000 / delta).roundToDouble();
        _controller.add(_currentFps);
        _frameCount = 0;
        _lastTimestamp = now;
      }
    });

    _ticker?.start();
  }

  static void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _frameCount = 0;
    _lastTimestamp = 0;
  }

  static void dispose() {
    stop();
    if (!_controller.isClosed) _controller.close();
  }
}

/// Mixin — use FPS monitor in any StatefulWidget
mixin SilkFpsMonitorMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  double currentFps = 0;
  StreamSubscription<double>? _fpsSub;

  @override
  void initState() {
    super.initState();
    SilkFpsMonitor.start(this);
    _fpsSub = SilkFpsMonitor.fpsStream.listen((fps) {
      if (mounted) setState(() => currentFps = fps);
    });
  }

  @override
  void dispose() {
    _fpsSub?.cancel();
    SilkFpsMonitor.stop();
    super.dispose();
  }
}
