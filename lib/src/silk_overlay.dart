import 'dart:async';
import 'package:flutter/material.dart';
import 'silk_fps_monitor.dart';

/// FPS Overlay Badge
/// [setHz] — Pass the refresh rate that has been set
/// [show] — Whether to show or hide the overlay
class SilkFpsOverlay extends StatefulWidget {
  final Widget child;
  final SilkOverlayPosition position;
  final bool show;
  final double? setHz; // Pass from outside — the selected refresh rate

  const SilkFpsOverlay({
    super.key,
    required this.child,
    this.position = SilkOverlayPosition.topRight,
    this.show = true,
    this.setHz, // Optional — shows max rate if null
  });

  @override
  State<SilkFpsOverlay> createState() => _SilkFpsOverlayState();
}

class _SilkFpsOverlayState extends State<SilkFpsOverlay>
    with TickerProviderStateMixin {
  double _flutterFps = 0;
  StreamSubscription<double>? _fpsSub;

  @override
  void initState() {
    super.initState();
    if (widget.show) {
      SilkFpsMonitor.start(this);
      _fpsSub = SilkFpsMonitor.fpsStream.listen((fps) {
        if (mounted) setState(() => _flutterFps = fps);
      });
    }
  }

  @override
  void dispose() {
    _fpsSub?.cancel();
    SilkFpsMonitor.stop();
    super.dispose();
  }

  Color _hzColor(double hz) {
    if (hz >= 90) return const Color(0xFF4CAF50);
    if (hz >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _fpsColor(double fps) {
    if (fps >= 85) return const Color(0xFF4CAF50);
    if (fps >= 55) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final hz = widget.setHz ?? 0;

    return Stack(
      children: [
        widget.child,
        if (widget.show)
          Positioned(
            top: _isTop ? 46 : null,
            bottom: !_isTop ? 20 : null,
            left: _isLeft ? 10 : null,
            right: !_isLeft ? 10 : null,
            child: Column(
              crossAxisAlignment: _isLeft
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (hz > 0)
                  _Badge(
                    label: '${hz.toStringAsFixed(0)} Hz',
                    color: _hzColor(hz),
                  ),
                const SizedBox(height: 4),
                if (_flutterFps > 0)
                  _Badge(
                    label: '${_flutterFps.toStringAsFixed(0)} FPS',
                    color: _fpsColor(_flutterFps),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  bool get _isTop =>
      widget.position == SilkOverlayPosition.topLeft ||
      widget.position == SilkOverlayPosition.topRight;

  bool get _isLeft =>
      widget.position == SilkOverlayPosition.topLeft ||
      widget.position == SilkOverlayPosition.bottomLeft;
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

enum SilkOverlayPosition { topLeft, topRight, bottomLeft, bottomRight }
