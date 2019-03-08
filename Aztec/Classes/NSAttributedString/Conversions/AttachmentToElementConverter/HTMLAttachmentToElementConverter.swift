import Foundation
import UIKit

class HTMLAttachmentToElementConverter: AttachmentToElementConverter {
    func convert(_ attachment: HTMLAttachment, attributes: [NSAttributedString.Key : Any]) -> [Node] {
        let htmlParser = HTMLParser()
        let rootNode = htmlParser.parse(attachment.rawHTML)
        
        return rootNode.children
    }
}
