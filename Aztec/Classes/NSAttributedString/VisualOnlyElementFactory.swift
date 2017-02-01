import Foundation

/// This class has the only responsibility of creating visual-only elements.
///
class VisualOnlyElementFactory {

    /// Creates a visual-only newline, inheriting the specified string attributes.
    ///
    /// - Parameters:
    ///     - inheritedAttributes: the string attributes that the newline must inherit.
    ///             Defaults to `nil`.
    ///
    /// - Returns: the requested visual-only newline.
    ///
    func newline(inheritingAttributes inheritedAttributes: [String:Any]? = nil) -> NSAttributedString {
        var attributes = inheritedAttributes ?? [String:Any]()

        attributes[VisualOnlyAttributeName] = VisualOnlyElement.newline

        return NSAttributedString(string: "\n", attributes: attributes)
    }
}
