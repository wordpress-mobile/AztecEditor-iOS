import UIKit

#if swift(>=4.0)
#else
    extension UILayoutPriority {
        static let defaultLow = UILayoutPriorityDefaultLow
    }
#endif
