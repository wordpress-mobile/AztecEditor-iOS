import UIKit

class HRInserter: Inserter {

    func attachment(from element: ElementNode, inheriting inheritedAttributes: [AttributedStringKey: Any]) -> NSTextAttachment? {
        return LineAttachment()
    }

    func specialString(for element: ElementNode) -> String {
        return String(UnicodeScalar(NSAttachmentCharacter)!)
    }

}
