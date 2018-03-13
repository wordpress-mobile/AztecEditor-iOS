import UIKit


/// Returns a specialised representation for a `<figcaption>` element.
///
class FigcaptionElementConverter: ElementConverter {

    unowned let serializer: AttributedStringSerializer

    // MARK: - Initializer
    
    init(using serializer: AttributedStringSerializer) {
        self.serializer = serializer
    }

    // MARK: - ElementConverter

    func canConvert(element: ElementNode) -> Bool {
        return element.isNodeType(.figcaption)
    }

    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        assert(canConvert(element: element))
        
        let attributes = self.attributes(for: element, inheriting: attributes)
        let content = NSMutableAttributedString()
        
        for child in element.children {
            let childContent = serializer.serialize(child, inheriting: attributes)
            content.append(childContent)
        }
        
        return content
    }
    
    private func attributes(for element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        let paragraphStyle = attributes.paragraphStyle()
        paragraphStyle.appendProperty(Figcaption())
        
        var finalAttributes = attributes
        finalAttributes[.paragraphStyle] = paragraphStyle
        return finalAttributes
    }
}

