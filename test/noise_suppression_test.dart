import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noise_suppression/noise_suppression.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('noise_suppression');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('engineInfo reads the native answer', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'engineInfo');
      return {'engine': 'rnnoise 0.1.1', 'sampleRate': 48000, 'frameSize': 480};
    });
    final info = await NoiseSuppression().engineInfo();
    expect(info.engine, 'rnnoise 0.1.1');
    expect(info.sampleRate, 48000);
    expect(info.frameSize, 480);
  });

  test('engineInfo passes a native error on', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    expect(NoiseSuppression().engineInfo(), throwsA(isA<PlatformException>()));
  });
}
