import Aztec
import Foundation

class GalleryElementToTagConverter: ElementToTagConverter {
    func convert(_ elementNode: ElementNode) -> ElementToTagConverter.Tag {
        let shortcode = self.shortcode(for: elementNode)
        
        return (shortcode, nil)
    }
}

// MARK: - Shortcode Construction

private extension GalleryElementToTagConverter {
    private func shortcode(for elementNode: ElementNode) -> String {
        let attributes = serialize(attributes: elementNode.attributes)
        
        return "[gallery " + attributes + "]"
    }
}

// MARK: - Attribute Conversion Logic

private extension GalleryElementToTagConverter {
    /// Serializes an array of attributes into their HTML representation
    ///
    private func serialize(attributes: [Attribute]) -> String {
        return attributes.reduce("") { (html, attribute) in
            let prefix = html.count > 0 ? html + " " : ""
            
            return prefix + attribute.toString()
        }
    }
}
