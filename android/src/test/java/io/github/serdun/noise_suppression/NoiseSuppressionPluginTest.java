package io.github.serdun.noise_suppression;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.junit.Test;

/** JVM test of the method channel; the engine itself is tested by `make test` and on a device. */
public class NoiseSuppressionPluginTest {
  @Test
  public void unknownMethodIsNotImplemented() {
    NoiseSuppressionPlugin plugin = new NoiseSuppressionPlugin();
    MethodChannel.Result result = mock(MethodChannel.Result.class);
    plugin.onMethodCall(new MethodCall("nope", null), result);
    verify(result).notImplemented();
  }
}
