# noise_suppression

Experimental. Removes background noise from 10 ms frames of mono voice, behind the package's own interface. It does not depend on flutter_webrtc or any other audio stack: whoever owns the audio pipeline writes a small bridge from that pipeline to this interface.

Engine: RNNoise v0.1.1 (xiph, `6cbfd53eb348a8d394e0757b4025c6ded34eb2b6`, BSD-3-Clause), the classic model: about 110-140 KB of native code per ABI, about 1 ms per frame on a low-end Android phone. It works at 48 kHz, mono, exactly 480 samples per frame, float samples on the int16 scale. A frame of any other shape is left unchanged and the call says so, so the caller can fall back to its own processing.

RNNoise keeps any voice: it removes keyboard, clatter and steady background, not a colleague talking nearby.

## The interface

| Layer | Contract | Implementation |
|---|---|---|
| C | `noise_suppressor.h`: `ns_create`, `ns_process`, `ns_reset`, `ns_destroy` | `noise_suppressor.c` over RNNoise |
| Android | `io.github.serdun.noise_suppression.NoiseSuppressor` (`initialize`, `process(ByteBuffer, int)`, `release`) | `RnnoiseSuppressor` (JNI) |
| iOS | `NSPNoiseSuppressor` protocol (`initializeWithSampleRate:`, `processSamples:count:`, `releaseEngine`) | `NSPRnnoiseSuppressor` |
| Dart | `NoiseSuppression.engineInfo()`, `selfCheck()` | method channel `noise_suppression` |

Frames never go through Dart. `process` never allocates and is meant for the audio thread; calls on one instance are serialized by the caller.

## A bridge, in the app

The app, which already depends on both its audio stack and this package, adapts one to the other at its composition root. For flutter_webrtc's capture post-processing the bridge implements flutter_webrtc's processor interface and calls this package's one; neither package knows the other. Not part of this repository yet.

## Layout

- `ios/noise_suppression/Sources/NoiseSuppressionCore/` - the C core and vendored RNNoise, one copy. It lives inside the Swift package because SwiftPM cannot reach sources outside its package directory; the Android CMake build compiles the same files.
- `ios/noise_suppression/Sources/noise_suppression/` - the iOS protocol, the RNNoise class and the Flutter plugin (Swift Package Manager and CocoaPods).
- `android/` - the Java interface, the RNNoise class over JNI, the Flutter plugin.
- `lib/` - Dart: engine info and the device self check.
- `test/native/` - host test of the C core.
- `example/` - shows the self check; `example/integration_test/` asserts it on a device.

## Checks

```sh
make test                 # C core on the host
flutter analyze && flutter test
cd example && flutter build apk --debug
cd example && flutter build ios --no-codesign --debug
cd example && flutter test integration_test   # on a device
cd example/ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=<iPhone>' -only-testing:RunnerTests
```

`selfCheck` runs 3 s of white noise through a suppressor via its interface and reports the attenuation and the time per frame. It shows the engine runs on a device; it is not a measurement of call quality.

Last run on devices (2026-11-03, `flutter test integration_test`, debug build):

| Device | Android | Attenuation | Mean time per 10 ms frame |
|---|---|---|---|
| Samsung SM-T505 | 12 | 15.1 dB | 377 us |
| Xiaomi 25028RN03Y | 15 (Go) | 15.1 dB | 324 us |

iOS: RunnerTests passed on the iPhone 17e simulator; not run on a phone yet. CocoaPods path not built yet.

## Traps

- Clone it into a directory named `noise_suppression`. With Swift Package Manager, Xcode takes a local package's identity from the directory name and refuses the plugin when the two differ (`unable to override package 'noise_suppression' because its identity ... doesn't match`).
- iOS 15.0 is the lowest target: Xcode 27 accepts nothing older.
- RNNoise keeps its FFT state in a global named `common`; every build defines `common=ns_rnnoise_common` so it cannot collide with another library in the process.
- RNNoise builds its FFT tables with `malloc` on the first frame; `ns_create` runs one frame of silence so that happens off the audio thread.
- `rnnoise_init` on a live state leaks its GRU buffers; `ns_reset` replaces the state instead (it allocates, so not per frame).
