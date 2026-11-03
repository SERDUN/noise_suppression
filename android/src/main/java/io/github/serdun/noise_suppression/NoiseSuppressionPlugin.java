package io.github.serdun.noise_suppression;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.HashMap;
import java.util.Map;

/**
 * Flutter side of the package: reports which engine is built in. Frames never go through Dart;
 * native code of the app takes a {@link NoiseSuppressor} and puts it into its audio pipeline.
 */
public class NoiseSuppressionPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), "noise_suppression");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    if ("engineInfo".equals(call.method)) {
      Map<String, Object> info = new HashMap<>();
      try {
        RnnoiseSuppressor probe = new RnnoiseSuppressor();
        info.put("engine", probe.engine());
        probe.release();
        info.put("sampleRate", RnnoiseSuppressor.sampleRate());
        info.put("frameSize", RnnoiseSuppressor.frameSize());
        result.success(info);
      } catch (Throwable error) {
        result.error("unavailable", String.valueOf(error), null);
      }
    } else if ("selfCheck".equals(call.method)) {
      try {
        result.success(selfCheck(new RnnoiseSuppressor()));
      } catch (Throwable error) {
        result.error("unavailable", String.valueOf(error), null);
      }
    } else {
      result.notImplemented();
    }
  }

  /**
   * Runs 3 s of white noise through a suppressor, through its interface only, and reports how much
   * quieter the last 2 s came out and how long a frame took. A check that the engine runs on this
   * device, not a measurement of call quality.
   */
  static Map<String, Object> selfCheck(NoiseSuppressor suppressor) {
    int rate = RnnoiseSuppressor.sampleRate();
    int n = RnnoiseSuppressor.frameSize();
    boolean ready = suppressor.initialize(rate);
    ByteBuffer frame = ByteBuffer.allocateDirect(n * 4).order(ByteOrder.nativeOrder());
    long seed = 12345;
    double in = 0, out = 0;
    long totalNs = 0;
    int processed = 0;
    for (int f = 0; f < 300; f++) {
      frame.clear();
      double sumIn = 0;
      for (int i = 0; i < n; i++) {
        seed = (seed * 1103515245L + 12345L) & 0xffffffffL;
        float x = 3000f * ((((seed >> 8) & 0xffff) / 32768f) - 1f);
        frame.putFloat(i * 4, x);
        sumIn += (double) x * x;
      }
      long t0 = System.nanoTime();
      NoiseSuppressor.Result r = suppressor.process(frame, n);
      totalNs += System.nanoTime() - t0;
      if (r == NoiseSuppressor.Result.PROCESSED) processed++;
      if (f >= 100) {
        double sumOut = 0;
        for (int i = 0; i < n; i++) {
          float y = frame.getFloat(i * 4);
          sumOut += (double) y * y;
        }
        in += Math.sqrt(sumIn / n);
        out += Math.sqrt(sumOut / n);
      }
    }
    Map<String, Object> report = new HashMap<>();
    report.put("engine", suppressor.engine());
    report.put("ready", ready);
    report.put("framesProcessed", processed);
    report.put("attenuationDb", 20 * Math.log10(in / (out + 1e-9)));
    report.put("meanFrameUs", totalNs / 300.0 / 1000.0);
    suppressor.release();
    return report;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
