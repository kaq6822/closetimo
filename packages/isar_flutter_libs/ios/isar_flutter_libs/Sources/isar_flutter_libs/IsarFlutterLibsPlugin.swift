import CIsarLegacyCore
import Flutter
import UIKit

public class IsarFlutterLibsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        isar_legacy_force_link_all_symbols()
    }
}
