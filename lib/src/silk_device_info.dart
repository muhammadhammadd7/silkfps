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

    String renderer = 'Skia';
    if (isVulkan) renderer = 'Vulkan';
    if (isMetal) renderer = 'Metal';

    return SilkDeviceInfo(
      manufacturer: map['manufacturer'] as String? ?? 'Unknown',
      model: map['model'] as String? ?? 'Unknown',
      osVersion:
          (map['androidVersion'] ?? map['iosVersion'] ?? 'Unknown') as String,
      apiLevel: map['apiLevel'] as int? ?? 0,
      isVulkanSupported: isVulkan,
      isMetalSupported: isMetal,
      isProMotion: maxRate >= 120,
      maxRefreshRate: maxRate,
      currentRefreshRate:
          (map['currentRefreshRate'] as num?)?.toDouble() ?? 60.0,
      supportedRefreshRates: supported,
      renderer: renderer,
    );
  }
}
