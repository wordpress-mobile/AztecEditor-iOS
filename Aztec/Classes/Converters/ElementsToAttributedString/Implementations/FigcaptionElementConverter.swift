import UIKit


/// Returns a specialised representation for a `<figcaption>` element.
///
class FigcaptionElementConverter: ElementConverter {
    
    let figcaptionFormatter = FigcaptionFormatter()

    // MARK: - ElementConverter

    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString {
        
        precondition(element.type == .figcaption)
        
        let attributes = self.attributes(for: element, inheriting: attributes)
        
        return serialize(element, nil, attributes, false)
    }
    
    private func attributes(for element: ElementNode, inheriting attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        
        return figcaptionFormatter.apply(to: attributes, andStore: representation)
    }
}

