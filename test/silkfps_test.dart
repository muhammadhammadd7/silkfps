import 'package:flutter_test/flutter_test.dart';
import 'package:silkfps/silkfps.dart';
import 'package:silkfps/silkfps_platform_interface.dart';
import 'package:silkfps/silkfps_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSilkfpsPlatform
    with MockPlatformInterfaceMixin
    implements SilkfpsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SilkfpsPlatform initialPlatform = SilkfpsPlatform.instance;

  test('$MethodChannelSilkfps is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSilkfps>());
  });

  test('getPlatformVersion', () async {
    Silkfps silkfpsPlugin = Silkfps();
    MockSilkfpsPlatform fakePlatform = MockSilkfpsPlatform();
    SilkfpsPlatform.instance = fakePlatform;

    expect(await silkfpsPlugin.getPlatformVersion(), '42');
  });
}
