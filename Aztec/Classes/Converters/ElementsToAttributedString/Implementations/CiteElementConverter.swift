import UIKit


class CiteElementConverter: FormatterElementConverter {
    
    lazy var citeFormatter = CiteFormatter()
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting inheritedAttributes: [NSAttributedStringKey: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString {
        
        precondition(element.type == .cite)
        
        let childrenAttributes = attributes(for: element, inheriting: inheritedAttributes)
        
        return serialize(element, childrenAttributes)
    }
    
    // MARK: - FormatterElementConverter
    
    func formatter() -> AttributeFormatter {
        return citeFormatter
    }
}
