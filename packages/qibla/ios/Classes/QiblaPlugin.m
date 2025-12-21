#import "QiblaPlugin.h"
#if __has_include(<qibla/qibla-Swift.h>)
#import <qibla/qibla-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "qibla-Swift.h"
#endif

@implementation QiblaPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [SwiftQiblaPlugin registerWithRegistrar:registrar];
}
@end
