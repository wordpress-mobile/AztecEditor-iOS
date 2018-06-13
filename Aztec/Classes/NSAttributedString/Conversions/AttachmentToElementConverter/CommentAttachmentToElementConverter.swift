import Foundation
import UIKit

class CommentAttachmentToElementConverter: AttachmentToElementConverter {
    func convert(_ attachment: CommentAttachment, attributes: [NSAttributedStringKey : Any]) -> [Node] {
        let node = CommentNode(text: attachment.text)
        
        return [node]
    }
}
