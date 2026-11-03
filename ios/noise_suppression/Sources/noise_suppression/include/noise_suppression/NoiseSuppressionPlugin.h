#import <Flutter/Flutter.h>

/// Flutter side of the package: reports which engine is built in. Frames never go through Dart;
/// native code of the app takes an NSPNoiseSuppressor and puts it into its audio pipeline.
@interface NoiseSuppressionPlugin : NSObject <FlutterPlugin>
@end
