import UIKit


/// Provides a representation for `<img>` element.
///
class ImageElementConverter: ElementConverter {

    func attachment(from representation: HTMLRepresentation, inheriting inheritedAttributes: [AttributedStringKey: Any]) -> NSTextAttachment? {

        guard case let .element(element) = representation.kind else {
            return nil
        }

        var extraAttributes = [String: String]()
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

        return attachment
    }

    func specialString(for element: ElementNode) -> String {
        return .textAttachment
    }

    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .img
    }
}
