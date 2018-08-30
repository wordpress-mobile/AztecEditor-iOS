import UIKit


/// Returns a specialised representation for a `<figcaption>` element.
///
class FigcaptionElementConverter: ElementConverter {
    
    let figcaptionFormatter = FigcaptionFormatter(placeholderAttributes: nil)

    // MARK: - ElementConverter

    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        precondition(element.type == .figcaption)
        
        let attributes = self.attributes(for: element, inheriting: attributes)
        
        return serializeChildren(element.children, attributes)
    }
    
    private func attributes(for element: ElementNode, inheriting attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        
        return figcaptionFormatter.apply(to: attributes, andStore: representation)
    }
}

