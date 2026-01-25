import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "com.safegallery/lock"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let lockChannel = FlutterMethodChannel(name: CHANNEL,
                                              binaryMessenger: controller.binaryMessenger)

        lockChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard self != nil else { return }

            switch call.method {
            case "enterPresentationMode":
                self?.enterPresentationMode()
                result(nil)
            case "exitPresentationMode":
                self?.exitPresentationMode()
                result(nil)
            case "lockDevice":
                // iOS doesn't allow programmatic device locking
                // User must use Guided Access or the app will just background
                // When app backgrounds, Flutter will detect it and can show appropriate UI
                result(false)
            case "isDeviceAdminEnabled":
                // Not applicable on iOS
                result(false)
            case "requestDeviceAdmin":
                // Not applicable on iOS
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func enterPresentationMode() {
        DispatchQueue.main.async {
            // Hide status bar
            if let window = UIApplication.shared.windows.first {
                window.windowLevel = .statusBar + 1
            }

            // Keep screen on
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    private func exitPresentationMode() {
        DispatchQueue.main.async {
            // Show status bar
            if let window = UIApplication.shared.windows.first {
                window.windowLevel = .normal
            }

            // Allow screen to sleep
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
