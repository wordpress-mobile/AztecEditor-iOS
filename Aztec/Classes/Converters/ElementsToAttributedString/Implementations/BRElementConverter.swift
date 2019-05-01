import UIKit


/// Converts `<br>` elements into a `String(.lineSeparator)`.
///
class BRElementConverter: ElementConverter {
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString {
        
        precondition(element.type == .br)
        
        let intrinsicRepresentation = NSAttributedString(.lineSeparator, attributes: attributes)
        
        return serialize(element, intrinsicRepresentation, attributes, false)
    }
}
