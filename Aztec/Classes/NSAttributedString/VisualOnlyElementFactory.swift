import Foundation

/// This class has the only responsibility of creating visual-only elements.
///
class VisualOnlyElementFactory {

    /// Creates a visual-only newline, inheriting the specified string attributes.
    ///
    /// - Parameters:
    ///     - inheritedAttributes: the string attributes that the element must inherit.
    ///             Defaults to `nil`.
    ///
    /// - Returns: the requested visual-only element.
    ///
    func newline(inheritingAttributes inheritedAttributes: [String:Any]? = nil) -> NSAttributedString {
        var attributes = inheritedAttributes ?? [String:Any]()

        attributes[VisualOnlyAttributeName] = VisualOnlyElement.newline

        return NSAttributedString(.newline, attributes: attributes)
    }

    /// Creates a visual-only zero width space, inheriting the specified string attributes.
    ///
    /// - Parameters:
    ///     - inheritedAttributes: the string attributes that the element must inherit.
    ///             Defaults to `nil`.
    ///
    /// - Returns: the requested visual-only element.
    ///
    func zeroWidthSpace(inheritingAttributes inheritedAttributes: [String:Any]? = nil) -> NSAttributedString {
        var attributes = inheritedAttributes ?? [String:Any]()

        attributes[VisualOnlyAttributeName] = VisualOnlyElement.zeroWidthSpace

        return NSAttributedString(.zeroWidthSpace, attributes: attributes)
    }
}
