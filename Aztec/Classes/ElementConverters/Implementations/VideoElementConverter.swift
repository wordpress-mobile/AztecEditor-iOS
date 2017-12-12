import UIKit


/// Provides a representation for `<video>` element.
///
class VideoElementConverter: ElementConverter {

    func attachment(from representation: HTMLRepresentation, inheriting inheritedAttributes: [AttributedStringKey: Any]) -> NSTextAttachment? {

        guard case let .element(element) = representation.kind else {
            return nil
        }

        var extraAttributes = [String:String]()

        for attribute in element.attributes {
            if let value = attribute.value.toString() {
                extraAttributes[attribute.name] = value
            }
        }

        let srcURL: URL?

        if let urlString = element.attribute(named: "src")?.value.toString() {
            srcURL = URL(string: urlString)
            extraAttributes.removeValue(forKey: "src")
        } else {
            srcURL = nil
        }

        let posterURL: URL?

        if let urlString = element.attribute(named: "poster")?.value.toString() {
            posterURL = URL(string: urlString)
            extraAttributes.removeValue(forKey: "poster")
        } else {
            posterURL = nil
        }

        let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL)

        attachment.extraAttributes = extraAttributes

        return attachment
    }

    func specialString(for element: ElementNode) -> String {
        return .textAttachment
    }

    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .video
    }
}
