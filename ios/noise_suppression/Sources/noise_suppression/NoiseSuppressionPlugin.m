#import "./include/noise_suppression/NoiseSuppressionPlugin.h"

#import "./include/noise_suppression/NSPRnnoiseSuppressor.h"

#include <math.h>
#include <mach/mach_time.h>

/// Runs 3 s of white noise through a suppressor, through its protocol only, and reports how much
/// quieter the last 2 s came out and how long a frame took. A check that the engine runs on this
/// device, not a measurement of call quality.
static NSDictionary* SelfCheck(id<NSPNoiseSuppressor> suppressor) {
  NSInteger rate = NSPRnnoiseSuppressor.sampleRate;
  NSInteger n = NSPRnnoiseSuppressor.frameSize;
  BOOL ready = [suppressor initializeWithSampleRate:rate];
  float* frame = calloc((size_t)n, sizeof(float));
  uint32_t seed = 12345;
  double in = 0, out = 0;
  uint64_t ticks = 0;
  int processed = 0;
  for (int f = 0; f < 300; f++) {
    double sumIn = 0;
    for (NSInteger i = 0; i < n; i++) {
      seed = seed * 1103515245u + 12345u;
      float x = 3000.0f * (((float)((seed >> 8) & 0xffff) / 32768.0f) - 1.0f);
      frame[i] = x;
      sumIn += (double)x * x;
    }
    uint64_t t0 = mach_absolute_time();
    NSPNoiseSuppressorResult r = [suppressor processSamples:frame count:n];
    ticks += mach_absolute_time() - t0;
    if (r == NSPNoiseSuppressorResultProcessed) processed++;
    if (f >= 100) {
      double sumOut = 0;
      for (NSInteger i = 0; i < n; i++) sumOut += (double)frame[i] * frame[i];
      in += sqrt(sumIn / n);
      out += sqrt(sumOut / n);
    }
  }
  free(frame);
  mach_timebase_info_data_t tb;
  mach_timebase_info(&tb);
  double meanUs = (double)ticks * tb.numer / tb.denom / 300.0 / 1000.0;
  NSDictionary* report = @{
    @"engine" : suppressor.engine,
    @"ready" : @(ready),
    @"framesProcessed" : @(processed),
    @"attenuationDb" : @(20.0 * log10(in / (out + 1e-9))),
    @"meanFrameUs" : @(meanUs),
  };
  [suppressor releaseEngine];
  return report;
}

@implementation NoiseSuppressionPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel =
      [FlutterMethodChannel methodChannelWithName:@"noise_suppression"
                                  binaryMessenger:[registrar messenger]];
  NoiseSuppressionPlugin* instance = [[NoiseSuppressionPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"engineInfo" isEqualToString:call.method]) {
    NSPRnnoiseSuppressor* probe = [[NSPRnnoiseSuppressor alloc] init];
    if (probe == nil) {
      result([FlutterError errorWithCode:@"unavailable" message:@"no memory" details:nil]);
      return;
    }
    result(@{
      @"engine" : probe.engine,
      @"sampleRate" : @(NSPRnnoiseSuppressor.sampleRate),
      @"frameSize" : @(NSPRnnoiseSuppressor.frameSize),
    });
  } else if ([@"selfCheck" isEqualToString:call.method]) {
    NSPRnnoiseSuppressor* suppressor = [[NSPRnnoiseSuppressor alloc] init];
    if (suppressor == nil) {
      result([FlutterError errorWithCode:@"unavailable" message:@"no memory" details:nil]);
      return;
    }
    result(SelfCheck(suppressor));
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
