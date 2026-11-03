/// Background noise suppression for 10 ms frames of mono voice.
///
/// Frames never go through Dart: native code of the app takes the package's native suppressor
/// (`NoiseSuppressor` on Android, `NSPNoiseSuppressor` on iOS) and puts it into its own audio
/// pipeline. Dart only asks which engine is built in.
library;

import 'package:flutter/services.dart';

/// The engine built into the package.
class NoiseSuppressionEngine {
  const NoiseSuppressionEngine({
    required this.engine,
    required this.sampleRate,
    required this.frameSize,
  });

  /// Name and version, e.g. `rnnoise 0.1.1`.
  final String engine;

  /// The only sample rate the engine accepts, Hz.
  final int sampleRate;

  /// Samples per frame the engine accepts.
  final int frameSize;

  @override
  String toString() => '$engine ($sampleRate Hz, $frameSize samples)';
}

/// Dart side of the package.
class NoiseSuppression {
  NoiseSuppression({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('noise_suppression');

  final MethodChannel _channel;

  /// Which engine the native side carries. Throws [PlatformException] when the
  /// native library cannot be loaded or its state cannot be allocated.
  Future<NoiseSuppressionEngine> engineInfo() async {
    final info = await _channel.invokeMapMethod<String, Object?>('engineInfo');
    if (info == null) {
      throw PlatformException(code: 'unavailable', message: 'no engine info');
    }
    return NoiseSuppressionEngine(
      engine: info['engine']! as String,
      sampleRate: info['sampleRate']! as int,
      frameSize: info['frameSize']! as int,
    );
  }

  /// Runs 3 s of white noise through a native suppressor on this device and
  /// reports how much quieter it came out (`attenuationDb`), how many of the
  /// 300 frames were processed (`framesProcessed`) and the mean time of one
  /// frame (`meanFrameUs`). It shows the engine runs here; it is not a
  /// measurement of call quality.
  Future<Map<String, Object?>> selfCheck() async {
    final report = await _channel.invokeMapMethod<String, Object?>('selfCheck');
    if (report == null) {
      throw PlatformException(code: 'unavailable', message: 'no report');
    }
    return report;
  }
}
