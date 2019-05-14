import UIKit


/// Converts `<li>` elements into a `String(.lineSeparator)`.
///
class LIElementConverter: ElementConverter {
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString {
        
        precondition(element.type == .li)

        var intrinsicRepresentation: NSAttributedString?
        let intrisicRepresentationBeforeChildren = !hasNonEmptyTextChildren(node: element) && hasNestedList(node: element)

        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        let formatter = LiFormatter(placeholderAttributes: nil)
        let finalAttributes = formatter.apply(to: attributes, andStore: representation)

        if intrisicRepresentationBeforeChildren {
            intrinsicRepresentation = NSAttributedString(string: String(.paragraphSeparator), attributes: finalAttributes)
        }

        return serialize(element, intrinsicRepresentation, finalAttributes, intrisicRepresentationBeforeChildren)
    }

    private func hasNonEmptyTextChildren(node: ElementNode) -> Bool {
        var result = false
        var whiteSpaces = CharacterSet.whitespacesAndNewlines
        whiteSpaces.remove(charactersIn: String(.paragraphSeparator))
        for node in node.children {
            if let text = node as? TextNode, !text.contents.trimmingCharacters(in: whiteSpaces).isEmpty {
                return true
            }
            if let element = node as? ElementNode, !element.isNodeType(.ol) && !element.isNodeType(.ul) {
                result = result || hasNonEmptyTextChildren(node: element)
            }
        }
        return result
    }

    private func hasNestedList(node: ElementNode) -> Bool {
        for node in node.children {
            if let element = node as? ElementNode, element.isNodeType(.ol) || element.isNodeType(.ul) {
                return true
            }
        }
        return false
    }
}
