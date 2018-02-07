import UIKit


/// Provides a representation for `<video>` element.
///
class VideoElementConverter: AttachmentElementConverter {
    
    // MARK: - ElementConverter
    
    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .video
    }
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = VideoAttachment
    
    func convert(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> (attachment: VideoAttachment, string: NSAttributedString) {
        let attachment = self.attachment(for: element)
        
        return (attachment, NSAttributedString(attachment: attachment, attributes: attributes))
    }
    
    // MARK: - Attachment Creation
    
    func attachment(for element: ElementNode) -> VideoAttachment {
        var extraAttributes = [String:String]()

        for attribute in element.attributes {
            if let value = attribute.value.toString() {
                extraAttributes[attribute.name] = value
            }
        }

        let srcURL: URL?
        let srcAttribute = element.attributes.first(where: { $0.name == "src" })
        
        if let urlString = srcAttribute?.value.toString() {
            srcURL = URL(string: urlString)
            extraAttributes.removeValue(forKey: "src")
        } else {
            srcURL = nil
        }

        let posterURL: URL?
        let classAttribute = element.attributes.first(where: { $0.name == "class" })
        
        if let urlString = classAttribute?.value.toString() {
            posterURL = URL(string: urlString)
            extraAttributes.removeValue(forKey: "poster")
        } else {
            posterURL = nil
        }

        let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL)

        attachment.extraAttributes = extraAttributes

        return attachment
    }
}
