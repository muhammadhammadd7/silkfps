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
    return const MaterialApp(
      title: 'SilkFPS Example',
      debugShowCheckedModeBanner: false,
      home: SilkFpsHomePage(),
    );
  }
}

class SilkFpsHomePage extends StatefulWidget {
  const SilkFpsHomePage({super.key});

  @override
  State<SilkFpsHomePage> createState() => _SilkFpsHomePageState();
}

class _SilkFpsHomePageState extends State<SilkFpsHomePage> {
  double _selectedFps = 0; // Jo button selected hai — badge mein yahi dikhao
  List<double> _supportedRates = [];
  bool _isVulkan = false;
  SilkDeviceInfo? _deviceInfo;
  bool _loading = true;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() => _loading = true);
    final supported = await SilkFps.getSupportedRefreshRates();
    final vulkan = await SilkFps.isVulkanSupported();
    final info = await SilkFps.getDeviceInfo();
    final maxRate = supported.isNotEmpty ? supported.last : 60.0;
    setState(() {
      _selectedFps = maxRate; // Default max rate
      _supportedRates = supported;
      _isVulkan = vulkan;
      _deviceInfo = info;
      _loading = false;
    });
  }

  Future<void> _setRate(double rate) async {
    setState(() {
      _applying = true;
      _selectedFps = rate;
    });
    await SilkFps.setRefreshRate(rate);
    setState(() => _applying = false);
  }

  Future<void> _setHighRate() async {
    setState(() => _applying = true);
    await SilkFps.setHighRefreshRate();
    final maxRate = _supportedRates.isNotEmpty ? _supportedRates.last : 60.0;
    setState(() {
      _selectedFps = maxRate;
      _applying = false;
    });
  }

  Color get _fpsColor {
    if (_selectedFps >= 90) return const Color(0xFF4CAF50);
    if (_selectedFps >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      // ✅ SilkFpsOverlay — selected rate pass karo
      body: SilkFpsOverlay(
        show: SilkFps.showFpsOverlay,
        position: SilkOverlayPosition.topRight,
        setHz: _selectedFps, // ← Yahi badge mein dikhega
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎯 SilkFPS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Silk smooth FPS for Flutter',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 30),

                      // Current FPS Card
                      _card(
                        child: Column(
                          children: [
                            const Text(
                              'Current Refresh Rate',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _applying
                                ? const SizedBox(
                                    height: 60,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF6C63FF),
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${_selectedFps.toStringAsFixed(0)} Hz',
                                    style: TextStyle(
                                      color: _fpsColor,
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isVulkan
                                    ? const Color(0xFF4CAF50).withOpacity(0.2)
                                    : const Color(0xFF6C63FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isVulkan ? '⚡ Vulkan' : '🎨 Skia/Metal',
                                style: TextStyle(
                                  color: _isVulkan
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF6C63FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rate Buttons
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set Refresh Rate',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _supportedRates.map((rate) {
                                final isSelected = _selectedFps == rate;
                                return GestureDetector(
                                  onTap: _applying
                                      ? null
                                      : () => _setRate(rate),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF6C63FF)
                                          : const Color(0xFF1E1E2E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF6C63FF)
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Text(
                                      '${rate.toStringAsFixed(0)} Hz',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white60,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Device Info
                      if (_deviceInfo != null)
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Device Info',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _row('Manufacturer', _deviceInfo!.manufacturer),
                              _row('Model', _deviceInfo!.model),
                              _row('OS Version', _deviceInfo!.osVersion),
                              _row('Renderer', _deviceInfo!.renderer),
                              _row(
                                'Vulkan',
                                '${_deviceInfo!.isVulkanSupported}',
                              ),
                              _row('ProMotion', '${_deviceInfo!.isProMotion}'),
                              _row(
                                'Max FPS',
                                '${_deviceInfo!.maxRefreshRate.toStringAsFixed(0)} Hz',
                              ),
                              _row(
                                'Supported',
                                _deviceInfo!.supportedRefreshRates
                                    .map((r) => '${r.toStringAsFixed(0)}Hz')
                                    .join(', '),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Set High FPS Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _applying ? null : _setHighRate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            disabledBackgroundColor: const Color(
                              0xFF6C63FF,
                            ).withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _applying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  '🚀 Set High Refresh Rate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}
