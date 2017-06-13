import Foundation
import UIKit


// MARK: - Text List
//
open class TextList: Equatable
{
    // MARK: - Nested Types

    /// List Styles
    ///
    public enum Style: Int {
        case ordered
        case unordered

        func markerText(forItemNumber number: Int) -> String {
            switch self {
            case .ordered:      return "\t\(number).\t"
            case .unordered:    return "\t\u{2022}\t\t"
            }
        }

       public var description: String {
            switch self {
            case .ordered: return "Ordered List"
            case .unordered: return "Unordered List"
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

    public static func ==(lhs: TextList, rhs: TextList) -> Bool {
        return lhs.style == rhs.style 
    }
}
