// import 'package:flutter_test/flutter_test.dart';
// import 'package:wns_flutter/wns_flutter.dart';
// import 'package:wns_flutter/wns_flutter_platform_interface.dart';
// import 'package:wns_flutter/wns_flutter_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockWnsFlutterPlatform
//     with MockPlatformInterfaceMixin
//     implements WnsFlutterPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final WnsFlutterPlatform initialPlatform = WnsFlutterPlatform.instance;
//
//   test('$MethodChannelWnsFlutter is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelWnsFlutter>());
//   });
//
//   test('getPlatformVersion', () async {
//     WnsFlutter wnsFlutterPlugin = WnsFlutter();
//     MockWnsFlutterPlatform fakePlatform = MockWnsFlutterPlatform();
//     WnsFlutterPlatform.instance = fakePlatform;
//
//     expect(await wnsFlutterPlugin.getPlatformVersion(), '42');
//   });
// }
