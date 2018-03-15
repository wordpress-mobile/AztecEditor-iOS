import UIKit


/// Converts a generic element to `NSAttributedString`.  Should only be used if a specific converter is not found.
///
class GenericElementConverter: ElementConverter {
    
    let serializeChildren: ChildrenSerializer
    
    required init(childrenSerializer: @escaping ChildrenSerializer) {
        self.serializeChildren = childrenSerializer
    }
    
    // MARK: - ElementConverter
    
    func canConvert(element: ElementNode) -> Bool {
        return true
    }
    
    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        return serializeChildren(element.children, attributes)
        /*
        for child in element.children {
            let childContent = serializer.serialize(child, inheriting: attributes)
            content.append(childContent)
        }
 */
    }
}

