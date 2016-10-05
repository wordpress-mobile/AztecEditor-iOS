import Foundation
import UIKit


// MARK: - NSParagraphStyle Helpers
//
extension NSParagraphStyle
{
    /// Aztec Awesomeness!
    ///
    struct Aztec {
        static let defaultParagraphStyle: NSParagraphStyle = {
            let style = NSMutableParagraphStyle()

            var tabStops = [NSTextTab]()

            for intervalNumber in (1 ..< tabStepCount) {
                let location = intervalNumber * tabStepInterval
                let textTab = NSTextTab(textAlignment: .Natural, location: CGFloat(location), options: [:])

                tabStops.append(textTab)
            }
            
            style.tabStops = tabStops
            
            return style
        }()

        private static let tabStepInterval = 8
        private static let tabStepCount    = 12
    }
}
