import UIKit


/// Provides a representation for `<video>` element.
///
class VideoElementConverter: AttachmentElementConverter {
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = VideoAttachment
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> (attachment: VideoAttachment, string: NSAttributedString) {
        
        let attachment = self.attachment(for: element)
        
        return (attachment, NSAttributedString(attachment: attachment, attributes: attributes))
    }
    
    // MARK: - Attachment Creation
    
    func attachment(for element: ElementNode) -> VideoAttachment {
        var extraAttributes = [Attribute]()

        for attribute in element.attributes {
            let copiedAttribute = Attribute(attribute)
            
            extraAttributes.append(copiedAttribute)
        }

        let srcURL: URL?
        let srcAttribute = element.attributes.first(where: { $0.name == "src" })
        
        if let urlString = srcAttribute?.value.toString() {
            srcURL = URL(string: urlString)
            
            extraAttributes.remove(named: "src")
        } else {
            srcURL = nil
        }

        let posterURL: URL?
        let posterAttribute = element.attributes.first(where: { $0.name == "poster" })
        
        if let urlString = posterAttribute?.value.toString() {
            posterURL = URL(string: urlString)
            
            extraAttributes.remove(named: "poster")
        } else {
            posterURL = nil
        }

        let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL)

        attachment.extraAttributes = extraAttributes

        return attachment
    }
}
