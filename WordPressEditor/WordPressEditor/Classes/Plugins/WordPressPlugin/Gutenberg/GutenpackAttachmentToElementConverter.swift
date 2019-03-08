import Aztec
import Foundation

class GutenpackAttachmentToElementConverter: AttachmentToElementConverter {

    let encoder = GutenbergAttributeEncoder()
    
    func convert(_ attachment: GutenpackAttachment, attributes: [NSAttributedString.Key : Any]) -> [Node] {
        let text = attachment.blockContent + "/"
        let attributes = [encoder.selfClosingAttribute(text)]
        let gutenpack = ElementNode(type: .gutenpack, attributes: attributes, children: [])

        return [gutenpack]
    }
}

