import UIKit


/// Returns a specialised representation for a `<figcaption>` element.
///
class FigcaptionElementConverter: ElementConverter {
    
    let serializeChildren: ChildrenSerializer
    
    required init(childrenSerializer: @escaping ChildrenSerializer) {
        self.serializeChildren = childrenSerializer
    }

    // MARK: - ElementConverter

    func canConvert(element: ElementNode) -> Bool {
        return element.isNodeType(.figcaption)
    }

    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        assert(canConvert(element: element))
        
        let attributes = self.attributes(for: element, inheriting: attributes)
        
        return serializeChildren(element.children, attributes)
    }
    
    private func attributes(for element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        let paragraphStyle = attributes.paragraphStyle()
        paragraphStyle.appendProperty(Figcaption())
        
        var finalAttributes = attributes
        finalAttributes[.paragraphStyle] = paragraphStyle
        return finalAttributes
    }
}

