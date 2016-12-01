import Foundation
import UIKit


// MARK: - Text List
//
class TextList
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

    var currentListNumber: Int = 0
    // MARK: Initializers

    init(style: Style) {
        self.style = style
    }

    // MARK: - Constants

    /// Attributed String's Attribute Name
    ///
    static let attributeName = "TextListAttributeName"
}




// MARK: - Encompases the entirety of a single text list item. Analogous to an LI tag
//
class TextListItem
{
    // MARK: - Properties

    /// Sequence Number
    ///
    var number = 0


    // MARK: - Initializers
    init(number: Int) {
        self.number = number
    }

    // MARK: - Constants

    /// Attributed String's Attribute Name
    ///
    static let attributeName = "TextListItemAttributeName"
}
