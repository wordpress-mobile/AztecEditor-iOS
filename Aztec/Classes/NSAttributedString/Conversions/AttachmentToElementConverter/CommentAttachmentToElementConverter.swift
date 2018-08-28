import Foundation
import UIKit

class CommentAttachmentToElementConverter: AttachmentToElementConverter {
    func convert(_ attachment: CommentAttachment, attributes: [NSAttributedString.Key : Any]) -> [Node] {
        let node = CommentNode(text: attachment.text)
        
        return [node]
    }
}
