#import "FlutterCompassPlugin.h"
#import <compass/compass-Swift.h>

@implementation FlutterCompassPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterCompassPlugin registerWithRegistrar:registrar];
}
@end
