import UIKit

class LinkElementConverter: ElementConverter {
    
    let linkFormatter = LinkFormatter()
    unowned let serializer: AttributedStringSerializer
    
    init(using serializer: AttributedStringSerializer) {
        self.serializer = serializer
    }
    
    // MARK: - ElementConverter
    
    func canConvert(element: ElementNode) -> Bool {
        return element.isNodeType(.a)
    }
    
    func convert(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {
        let content = NSMutableAttributedString()
        
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        let attributes = linkFormatter.apply(to: attributes, andStore: representation)
        
        for child in element.children {
            let childContent = serializer.serialize(child, inheriting: attributes)
            content.append(childContent)
        }
        
        return content
    }
}

