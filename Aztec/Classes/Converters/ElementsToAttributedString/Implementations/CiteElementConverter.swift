import UIKit


class CiteElementConverter: FormatterElementConverter {
    
    lazy var citeFormatter = CiteFormatter()
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting inheritedAttributes: [NSAttributedStringKey: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        precondition(element.type == .cite)
        
        let childrenAttributes = attributes(for: element, inheriting: inheritedAttributes)
        
        return serializeChildren(element.children, childrenAttributes)
    }
    
    // MARK: - FormatterElementConverter
    
    func formatter() -> AttributeFormatter {
        return citeFormatter
    }
}
