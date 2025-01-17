import Foundation
import UIKit

/// Converts the mark style information from string attributes and aggregates it into an
/// existing array of element nodes.
///
open class MarkStringAttributeConverter: StringAttributeConverter {

    private let toggler = HTMLStyleToggler(defaultElement: .mark, cssAttributeMatcher: ForegroundColorCSSAttributeMatcher())

    public func convert(
        attributes: [NSAttributedString.Key: Any],
        andAggregateWith elementNodes: [ElementNode]) -> [ElementNode] {

        var elementNodes = elementNodes

        // We add the representation right away, if it exists... as it could contain attributes beyond just this
        // style.  The enable and disable methods below can modify this as necessary.
        //

        if let elementNode = attributes.storedElement(for: NSAttributedString.Key.markHtmlRepresentation) {
            let styleAttribute = elementNode.attributes.first(where: { $0.name == "style" })
            if let elementStyle = styleAttribute?.value.toString() {
                // Remove spaces between attribute name and value, and between style attributes.
                let styleAttributes = elementStyle.replacingOccurrences(of: ": ", with: ":").replacingOccurrences(of: "; ", with: ";")
                elementNode.attributes["style"] = .string(styleAttributes)
            }
            elementNodes.append(elementNode)
        }

        if shouldEnableMarkElement(for: attributes) {
            return toggler.enable(in: elementNodes)
        } else {
            return toggler.disable(in: elementNodes)
        }
    }

    // MARK: - Style Detection

    func shouldEnableMarkElement(for attributes: [NSAttributedString.Key: Any]) -> Bool {
        return isMark(for: attributes)
    }

    func isMark(for attributes: [NSAttributedString.Key: Any]) -> Bool {
        return attributes[.markHtmlRepresentation] != nil
    }
}
