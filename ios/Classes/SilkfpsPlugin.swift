import Flutter
import UIKit

public class SilkfpsPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "silkfps", binaryMessenger: registrar.messenger())
        let instance = SilkfpsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "setHighRefreshRate":
            setHighRefreshRate()
            result(true)

        case "setRefreshRate":
            setHighRefreshRate() // iOS does not support custom refresh rate selection
            result(true)

        case "getCurrentRefreshRate":
            result(getCurrentRefreshRate())

        case "getSupportedRefreshRates":
            result(getSupportedRefreshRates())

        case "isVulkanSupported":
            result(false) // iOS uses Metal, not Vulkan

        case "getBatteryLevel":
            result(getBatteryLevel())

        case "getDeviceInfo":
            let info: [String: Any] = [
                "manufacturer": "Apple",
                "model": getDeviceModel(),
                "iosVersion": UIDevice.current.systemVersion,
                "apiLevel": 0,
                "isVulkanSupported": false,
                "isMetalSupported": true,
                "maxRefreshRate": getMaxRefreshRate(),
                "currentRefreshRate": getCurrentRefreshRate(),
                "supportedRefreshRates": getSupportedRefreshRates(),
                "batteryLevel": getBatteryLevel()
            ]
            result(info)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setHighRefreshRate() {
        if #available(iOS 15.0, *) {
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.forEach { window in
                        window.layer.contentsScale = UIScreen.main.scale
                    }
                }
            }
        }
    }

    private func getCurrentRefreshRate() -> Double {
        if #available(iOS 10.3, *) {
            return Double(UIScreen.main.maximumFramesPerSecond)
        }
        return 60.0
    }

    private func getMaxRefreshRate() -> Double {
        if #available(iOS 10.3, *) {
            return Double(UIScreen.main.maximumFramesPerSecond)
        }
        return 60.0
    }

    private func getSupportedRefreshRates() -> [Double] {
        let maxRate = getMaxRefreshRate()
        if maxRate >= 120 { return [60.0, 80.0, 120.0] }
        if maxRate >= 90  { return [60.0, 90.0] }
        return [60.0]
    }

    private func getBatteryLevel() -> Int {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        if level < 0 { return 100 }
        return Int(level * 100)
    }

    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}