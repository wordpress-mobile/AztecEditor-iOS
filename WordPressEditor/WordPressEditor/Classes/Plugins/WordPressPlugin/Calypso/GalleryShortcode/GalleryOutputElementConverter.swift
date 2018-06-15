import Aztec
import Foundation

class GalleryOutputElementConverter {
    func convert(_ elementNode: ElementNode) -> TextNode {
        let shortcode = self.shortcode(for: elementNode)
        
        return TextNode(text: shortcode)
    }

    // MARK: - Shortcode Construction

    private func shortcode(for elementNode: ElementNode) -> String {
        let attributes = serialize(attributes: elementNode.attributes)
        
        return "[gallery " + attributes + "]"
    }

    // MARK: - Attribute Conversion Logic

    /// Serializes an array of attributes into their HTML representation
    ///
    private func serialize(attributes: [Attribute]) -> String {
        return attributes.reduce("") { (html, attribute) in
            let prefix = html.count > 0 ? html + " " : ""
            
            return prefix + attribute.toString()
        }
    }
}
