import Aztec
import Foundation

class GutenblockConverter: ElementConverter {

    let serializeChildren: ChildrenSerializer
    
    required init(childrenSerializer: @escaping ChildrenSerializer) {
        self.serializeChildren = childrenSerializer
    }
    
    // MARK: - ElementConverter
    
    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .gutenblock
    }
    
    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        
        if element.isBlockLevel() {
            
        }
        
        return serializeChildren(element.children, attributes)
    }
}
