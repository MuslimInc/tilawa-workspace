import Flutter
import UIKit

public class SwiftQiblaPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ml.medyas.qibla", binaryMessenger: registrar.messenger())
    let instance = SwiftQiblaPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}

@objc(QiblaPlugin)
public class QiblaPlugin: NSObject {
  @objc(registerWithRegistrar:)
  public static func register(with registrar: FlutterPluginRegistrar) {
    SwiftQiblaPlugin.register(with: registrar)
  }
}
