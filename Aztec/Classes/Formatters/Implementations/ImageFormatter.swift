import UIKit

class ImageFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Image.htmlRepresentation"

    init() {
        super.init(
            attributeKey: NSAttachmentAttributeName,
            attributeValue: ImageAttachment(identifier: NSUUID().uuidString),
            htmlRepresentationKey: ImageFormatter.htmlRepresentationKey)
    }

    override func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {
        let elementRepresentation = representation as? HTMLElementRepresentation

        guard representation == nil || elementRepresentation != nil else {
            fatalError("This should not be possible.  Review the logic")
        }

        return apply(to: attributes, andStore: elementRepresentation)
    }

    func apply(to attributes: [String : Any], andStore representation: HTMLElementRepresentation?) -> [String: Any] {

        if let representation = representation {
            var namedAttributes = [String:String]()
            for attributeRepresentation in representation.attributes {
                if let value = attributeRepresentation.value {
                    namedAttributes[attributeRepresentation.name] = value
                }
            }

            let url: URL?

            if let urlString = representation.valueForAttribute(named: "src") {
                namedAttributes.removeValue(forKey: "src")
                url = URL(string: urlString)
            } else {
                url = nil
            }

            let attachment = ImageAttachment(identifier: UUID().uuidString, url: url)

            if let elementClass = representation.valueForAttribute(named: "class") {
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
                    namedAttributes.removeValue(forKey: "class")
                } else {
                    namedAttributes["class"] = remainingClassAttributes
                }
            }

            attachment.namedAttributes = namedAttributes            
            attributeValue = attachment
        } else {
            attributeValue = ImageAttachment(identifier: UUID().uuidString)
        }

        return super.apply(to: attributes, andStore: representation)
    }
}
