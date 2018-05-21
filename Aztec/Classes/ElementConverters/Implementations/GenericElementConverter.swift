import UIKit


/// Converts a generic element to `NSAttributedString`.  Should only be used if a specific converter is not found.
///
class GenericElementConverter: ElementConverter {
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedStringKey: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        return serializeChildren(element.children, attributes)
    }
}

