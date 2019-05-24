import UIKit


class CiteElementConverter: FormatterElementConverter {
    
    lazy var citeFormatter = CiteFormatter()
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting inheritedAttributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString {
        
        precondition(element.type == .cite)
        
        let childrenAttributes = attributes(for: element, inheriting: inheritedAttributes)
        
        return serialize(element, nil, childrenAttributes, false)
    }
    
    // MARK: - FormatterElementConverter
    
    func formatter() -> AttributeFormatter {
        return citeFormatter
    }
}
