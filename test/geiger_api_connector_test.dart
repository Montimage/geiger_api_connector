// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:geiger_api_connector/geiger_api_connector.dart';

// void main() {
//   const MethodChannel channel = MethodChannel('geiger_api_connector');

//   TestWidgetsFlutterBinding.ensureInitialized();

//   setUp(() {
//     channel.setMockMethodCallHandler((MethodCall methodCall) async {
//       return '42';
//     });
//   });

//   tearDown(() {
//     channel.setMockMethodCallHandler(null);
//   });

//   test('getPlatformVersion', () async {
//     expect(await GeigerApiConnector.platformVersion, '42');
//   });
// }
