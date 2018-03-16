import UIKit


/// Returns a specialised representation for a `<figcaption>` element.
///
class FigcaptionElementConverter: ElementConverter {
    
    typealias CaptionStyler = ([NSAttributedStringKey:Any]) -> [NSAttributedStringKey:Any]
    
    let captionStyler: CaptionStyler
    let serializeChildren: ChildrenSerializer
    
    required init(childrenSerializer: @escaping ChildrenSerializer) {
        self.captionStyler = { $0 }
        self.serializeChildren = childrenSerializer
    }
    
    required init(childrenSerializer: @escaping ChildrenSerializer, captionStyler: @escaping CaptionStyler) {
        self.captionStyler = captionStyler
        self.serializeChildren = childrenSerializer
    }

    // MARK: - ElementConverter

    func canConvert(element: ElementNode) -> Bool {
        return element.isNodeType(.figcaption)
    }

    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        assert(canConvert(element: element))
        
        let attributes = self.attributes(for: element, inheriting: attributes)
        let attributesWithCaptionStyle = captionStyler(attributes)
        
        return serializeChildren(element.children, attributesWithCaptionStyle)
    }
    
    private func attributes(for element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        let paragraphStyle = attributes.paragraphStyle()
        paragraphStyle.appendProperty(Figcaption())
        
        var finalAttributes = attributes
        finalAttributes[.paragraphStyle] = paragraphStyle
        return finalAttributes
    }
}

