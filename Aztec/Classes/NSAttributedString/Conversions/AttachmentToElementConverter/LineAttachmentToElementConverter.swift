import Foundation
import UIKit

class LineAttachmentToElementConverter: AttachmentToElementConverter {
    func convert(_ attachment: LineAttachment, attributes: [NSAttributedString.Key : Any]) -> [Node] {
        let element: ElementNode
        
        if let representation = attributes[.hrHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {
            
            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .hr)
        }
        
        return [element]
    }
}
