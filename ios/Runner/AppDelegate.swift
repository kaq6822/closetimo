import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // 005 — 기기 내 사진 분석 채널(배경 제거·분류·기기 내 AI).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ClosetimoVisionChannel") {
      ClosetimoVisionChannel.register(with: registrar.messenger())
    }
  }
}
