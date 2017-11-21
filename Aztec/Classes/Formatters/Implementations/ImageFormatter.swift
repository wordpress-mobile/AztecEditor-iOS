import UIKit

class ImageFormatter: StandardAttributeFormatter {

    init() {
        super.init(
            attributeKey: .attachment,
            attributeValue: ImageAttachment(identifier: NSUUID().uuidString),
            htmlRepresentationKey: .imageHtmlRepresentation)
    }

    override func apply(to attributes: [AttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [AttributedStringKey: Any] {

        if let representation = representation {
            switch representation.kind {
            case .element(let element):
                var extraAttributes = [String:String]()
                for attribute in element.attributes {
                    if let value = attribute.value.toString() {
                        extraAttributes[attribute.name] = value
                    }
                }

                let url: URL?

                if let urlString = element.attribute(named: "src")?.value.toString() {
                    extraAttributes.removeValue(forKey: "src")
                    url = URL(string: urlString)
                } else {
                    url = nil
                }

                    let attachment = ImageAttachment(identifier: UUID().uuidString, url: url)

                if let elementClass = element.attribute(named: "class")?.value.toString() {
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
                attributeValue = attachment
            default:
                attributeValue = ImageAttachment(identifier: UUID().uuidString)
            }
        }
        // Comment: Sergio Estevao (2017-10-30) - We are not passing the representation because it's all save inside the extraAttributes property of the attachment.
        return super.apply(to: attributes, andStore: nil)
    }
}
