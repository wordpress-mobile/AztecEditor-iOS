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
        case Ordered
        case Unordered
    }

    // MARK: - Properties

    /// Kind of List: Ordered / Unordered
    ///
    let style: Style


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

    ///
    ///
    var number = 0

    // MARK: - Constants

    /// Attributed String's Attribute Name
    ///
    static let attributeName = "TextListItemAttributeName"
}


// MARK: - Encompases the range of the bullet/number + tab.
//
class TextListItemMarker {
    // MARK: - Constants

    /// Attributed String's Attribute Name
    ///
    static let attributeName = "TextListItemMarkerAttributeName"
}
