import Foundation
import UIKit


// MARK: - NSParagraphStyle Helpers
//
extension NSParagraphStyle
{
    private struct AztecDefaultStyle {
        static let tabStepInterval = 8
        static let tabStepCount    = 12
    }

    static func aztecDefaultParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()

        var tabStops = [NSTextTab]()

        for intervalNumber in (1 ..< AztecDefaultStyle.tabStepCount) {
            let location = intervalNumber * AztecDefaultStyle.tabStepInterval
            let textTab = NSTextTab(textAlignment: .Natural, location: CGFloat(location), options: [:])

            tabStops.append(textTab)
        }

        style.tabStops = tabStops

        return style
    }
}
