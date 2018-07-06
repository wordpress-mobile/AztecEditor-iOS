import Aztec
import Foundation

class GutenpackAttachmentToElementConverter: AttachmentToElementConverter {

    let encoder = GutenbergAttributeEncoder()
    
    func convert(_ attachment: GutenpackAttachment, attributes: [NSAttributedStringKey : Any]) -> [Node] {
        
        let text = attachment.blockContent + "/"        
        let comment = CommentNode(text: text);

        return [comment]
    }
}

