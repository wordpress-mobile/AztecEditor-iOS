import UIKit


/// Provides a representation for `<img>` element.
///
class ImageElementConverter: AttachmentElementConverter {    
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = ImageAttachment
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedStringKey: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> (attachment: ImageAttachment, string: NSAttributedString) {
        
        let attachment = self.attachment(for: element)
        
        return (attachment, NSAttributedString(attachment: attachment, attributes: attributes))
    }
    
    // MARK: - Attachment Creation
    
    private func attachment(for element: ElementNode) -> ImageAttachment {
        var extraAttributes = [String: String]()
        for attribute in element.attributes {
            if let value = attribute.value.toString() {
                extraAttributes[attribute.name] = value
            }
        }

        let url: URL?
        let srcAttribute = element.attributes.first(where: { $0.name == "src" })
        
        if let urlString = srcAttribute?.value.toString() {
            extraAttributes.removeValue(forKey: "src")
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
                extraAttributes.removeValue(forKey: "class")
            } else {
                extraAttributes["class"] = remainingClassAttributes
            }
        }
        
        attachment.extraAttributes = extraAttributes

        return attachment
    }
}
