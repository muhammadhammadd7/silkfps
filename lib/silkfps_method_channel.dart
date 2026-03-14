import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'silkfps_platform_interface.dart';

/// An implementation of [SilkfpsPlatform] that uses method channels.
class MethodChannelSilkfps extends SilkfpsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('silkfps');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
