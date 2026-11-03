// On a device: flutter test integration_test (from example/).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:noise_suppression/noise_suppression.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the engine loads and denoises white noise', (tester) async {
    final plugin = NoiseSuppression();
    final info = await plugin.engineInfo();
    expect(info.engine, startsWith('rnnoise'));
    expect(info.sampleRate, 48000);
    expect(info.frameSize, 480);

    final report = await plugin.selfCheck();
    // ignore: avoid_print
    print('selfCheck: $report');
    expect(report['ready'], true);
    expect(report['framesProcessed'], 300);
    expect(report['attenuationDb'] as double, greaterThan(10));
  });
}
