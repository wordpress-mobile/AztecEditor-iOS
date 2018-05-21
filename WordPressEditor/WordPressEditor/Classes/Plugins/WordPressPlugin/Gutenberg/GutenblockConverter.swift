import Aztec
import Foundation

public extension Element {
    static let gutenblock = Element("gutenblock")
}

class GutenblockConverter: ElementConverter {
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedStringKey: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> NSAttributedString {
        
        precondition(element.type == .gutenblock)
        
        if element.isBlockLevel() {
            
        }
        
        return serializeChildren(element.children, attributes)
    }
}
