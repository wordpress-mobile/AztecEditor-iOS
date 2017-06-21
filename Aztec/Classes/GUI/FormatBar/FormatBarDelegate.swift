import Foundation
import UIKit

public enum FormatBarOverflowState {
    case hidden
    case visible
}

public protocol FormatBarDelegate : NSObjectProtocol {
    func handleActionForIdentifier(_ identifier: FormattingIdentifier, barItem: FormatBarItem)
    func formatBarTouchesBegan(_ formatBar: FormatBar)
    func formatBar(_ formatBar: FormatBar, didChangeOverflowState overflowState: FormatBarOverflowState)
}
