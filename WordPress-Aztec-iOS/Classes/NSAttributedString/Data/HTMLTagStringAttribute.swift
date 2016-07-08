import Foundation

/// Custom attribute for NSAttributedString, representing any HTML tag.
///
class HTMLTagStringAttribute {

    static let key = "HTMLTag"

    /// The tag name.  The node name.  For example in the case of `<strong>` the name would be
    /// "strong".
    ///
    let name: String

    init(name: String) {
        self.name = name
    }
}
