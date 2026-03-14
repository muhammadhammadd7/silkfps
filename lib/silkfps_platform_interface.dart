import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'silkfps_method_channel.dart';

abstract class SilkfpsPlatform extends PlatformInterface {
  /// Constructs a SilkfpsPlatform.
  SilkfpsPlatform() : super(token: _token);

  static final Object _token = Object();

  static SilkfpsPlatform _instance = MethodChannelSilkfps();

  /// The default instance of [SilkfpsPlatform] to use.
  ///
  /// Defaults to [MethodChannelSilkfps].
  static SilkfpsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SilkfpsPlatform] when
  /// they register themselves.
  static set instance(SilkfpsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
