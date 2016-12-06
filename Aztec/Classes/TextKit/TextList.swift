import Foundation
import UIKit


// MARK: - Text List
//
class TextList: Equatable
{
    // MARK: - Nested Types

    /// List Styles
    ///
    enum Style {
        case ordered
        case unordered

        func markerText(forItemNumber number: Int) -> String {
            switch self {
            case .ordered:      return "\(number).\t"
            case .unordered:    return "\u{2022}\t\t"
            }
        }
    }

    // MARK: - Properties

    /// Kind of List: Ordered / Unordered
    ///
    let style: Style

    init(style: Style) {
        self.style = style
    }

    static func ==(lhs: TextList, rhs: TextList) -> Bool {
        return lhs.style == rhs.style 
    }
}
