import UIKit


/// Provides a representation for `<img>` element.
///
class ImageElementConverter: AttachmentElementConverter {    
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = ImageAttachment
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> (attachment: ImageAttachment, string: NSAttributedString) {
        
        let attachment = self.attachment(for: element)
        let intrinsicRepresentation = NSAttributedString(attachment: attachment, attributes: attributes)
        let serialization = serialize(element, intrinsicRepresentation, attributes, false)
        
        return (attachment, serialization)
    }
    
    // MARK: - Attachment Creation
    
    private func attachment(for element: ElementNode) -> ImageAttachment {
        var extraAttributes = [Attribute]()
        
        for attribute in element.attributes {
            if let value = attribute.value.toString() {
                extraAttributes[attribute.name] = .string(value)
            }
        }

        let url: URL?
        let srcAttribute = element.attributes.first(where: { $0.name == "src" })
        
        if let urlString = srcAttribute?.value.toString() {
            extraAttributes.remove(named: "src")
            url = URL(string: urlString)
        } else {
            url = nil
        }

        let attachment = ImageAttachment(identifier: UUID().uuidString, url: url)
        let classAttribute = element.attributes.first(where: { $0.name == "class" })
        
        if let elementClass = classAttribute?.value.toString() {
            let classAttributes = elementClass.components(separatedBy: " ")
            var attributesToRemove = [String]()
            for classAttribute in classAttributes {
                if let alignment = ImageAttachment.Alignment.fromHTML(string: classAttribute) {
                    attachment.alignment = alignment
                    attributesToRemove.append(classAttribute)
                }
                if let size = ImageAttachment.Size.fromHTML(string: classAttribute) {
                    attachment.size = size
                    attributesToRemove.append(classAttribute)
                }
            }
            let otherAttributes = classAttributes.filter({ (value) -> Bool in
                return !attributesToRemove.contains(value)
            })
            let remainingClassAttributes = otherAttributes.joined(separator: " ")
            if remainingClassAttributes.isEmpty {
                extraAttributes.remove(named: "class")
            } else {
                extraAttributes["class"] = .string(remainingClassAttributes)
            }
        }
        
        attachment.extraAttributes = extraAttributes

        return attachment
    }
}
