import Foundation

extension Bundle {
    @objc public class var aztecBundle: Bundle {
        let defaultBundle = Bundle(for: EditorView.self)
        // If installed with CocoaPods, resources will be in WordPress-Aztec-iOS.bundle
        if let bundleURL = defaultBundle.resourceURL,
            let resourceBundle = Bundle(url: bundleURL.appendingPathComponent("WordPress-Aztec-iOS.bundle")) {
            return resourceBundle
        }
        // Otherwise, the default bundle is used for resources
        return defaultBundle
    }
}
