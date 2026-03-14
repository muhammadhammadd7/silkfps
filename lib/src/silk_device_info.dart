/// Complete display information for the device
class SilkDeviceInfo {
  final String manufacturer;
  final String model;
  final String osVersion;
  final int apiLevel;
  final bool isVulkanSupported;
  final bool isMetalSupported;
  final bool isProMotion;
  final double maxRefreshRate;
  final double currentRefreshRate;
  final List<double> supportedRefreshRates;
  final String renderer;

  /// Android renderer strategy based on API level:
  /// - "NOT_SUPPORTED" — Android 10 and below (API < 30)
  /// - "SKIA"          — Android 11-12L (API 30-32)
  /// - "IMPELLER"      — Android 13+ (API 33+)
  /// - "Metal"         — iOS (always)
  final String rendererStrategy;

  /// Whether this device supports high refresh rate via SilkFPS
  /// true = Android 11+ (API 30+) or iOS
  /// false = Android 10 and below
  final bool isHighRefreshRateSupported;

  const SilkDeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.osVersion,
    required this.apiLevel,
    required this.isVulkanSupported,
    required this.isMetalSupported,
    required this.isProMotion,
    required this.maxRefreshRate,
    required this.currentRefreshRate,
    required this.supportedRefreshRates,
    required this.renderer,
    required this.rendererStrategy,
    required this.isHighRefreshRateSupported,
  });

  factory SilkDeviceInfo.fromMap(Map<String, dynamic> map) {
    final supported =
        (map['supportedRefreshRates'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [60.0];
    final maxRate = (map['maxRefreshRate'] as num?)?.toDouble() ?? 60.0;
    final isVulkan = map['isVulkanSupported'] as bool? ?? false;
    final isMetal = map['isMetalSupported'] as bool? ?? false;
    final apiLevel = map['apiLevel'] as int? ?? 0;

    // Determine renderer string
    String renderer = 'Skia';
    if (isVulkan) renderer = 'Vulkan';
    if (isMetal) renderer = 'Metal';

    // Determine strategy
    final strategyFromMap = map['rendererStrategy'] as String?;
    String rendererStrategy;
    if (strategyFromMap != null) {
      rendererStrategy = strategyFromMap;
    } else if (isMetal) {
      rendererStrategy = 'Metal';
    } else if (apiLevel < 30) {
      rendererStrategy = 'NOT_SUPPORTED';
    } else if (apiLevel <= 32) {
      rendererStrategy = 'SKIA';
    } else {
      rendererStrategy = 'IMPELLER';
    }

    return SilkDeviceInfo(
      manufacturer: map['manufacturer'] as String? ?? 'Unknown',
      model: map['model'] as String? ?? 'Unknown',
      osVersion:
          (map['androidVersion'] ?? map['iosVersion'] ?? 'Unknown') as String,
      apiLevel: apiLevel,
      isVulkanSupported: isVulkan,
      isMetalSupported: isMetal,
      isProMotion: maxRate >= 120,
      maxRefreshRate: maxRate,
      currentRefreshRate:
          (map['currentRefreshRate'] as num?)?.toDouble() ?? 60.0,
      supportedRefreshRates: supported,
      renderer: renderer,
      rendererStrategy: rendererStrategy,
      isHighRefreshRateSupported:
          map['isHighRefreshRateSupported'] as bool? ?? (apiLevel >= 30),
    );
  }

  @override
  String toString() {
    return 'SilkDeviceInfo('
        'model: $manufacturer $model, '
        'api: $apiLevel, '
        'maxHz: $maxRefreshRate, '
        'renderer: $renderer, '
        'strategy: $rendererStrategy, '
        'supported: $isHighRefreshRateSupported'
        ')';
  }
}
