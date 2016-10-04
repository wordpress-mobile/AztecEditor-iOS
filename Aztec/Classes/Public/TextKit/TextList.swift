import Foundation
import UIKit


// MARK: - Text List
//
class TextList
{
    // MARK: - Nested Types

    /// Kind of Lists
    ///
    enum Kind {
        case Ordered
        case Unordered
    }

    // MARK: - Properties

    /// Kind of List: Ordered / Unordered
    ///
    let kind: Kind


    // MARK: Initializers

    init(kind: Kind) {
        self.kind = kind
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
