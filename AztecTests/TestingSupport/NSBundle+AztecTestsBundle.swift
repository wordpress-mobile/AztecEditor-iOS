import Foundation

extension Bundle {
    @objc public class var aztecTestsBundle: Bundle {
#if SPM
        return .module
#else
        return Bundle(for: TextViewStub.self)
#endif
    }
}
