import UIKit


/// Converts `<br>` elements into a `String(.lineSeparator)`.
///
class BRElementConverter: ElementConverter {
    
    let serializeChildren: ChildrenSerializer
    
    required init(childrenSerializer: @escaping ChildrenSerializer) {
        self.serializeChildren = childrenSerializer
    }
    
    // MARK: - ElementConverter
    
    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .br
    }
    
    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        return NSAttributedString(.lineSeparator, attributes: attributes)
    }
}
