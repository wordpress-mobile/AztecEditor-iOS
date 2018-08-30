import UIKit

class LinkFormatter: StandardAttributeFormatter {

    let target: String?

    init(target: String? = nil) {
        self.target = target
        super.init(attributeKey: .link,
                   attributeValue: NSURL(string:"")!,
                   htmlRepresentationKey: .linkHtmlRepresentation)
    }

    override func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        var finalRepresentation: HTMLRepresentation?

        if let representation = representation,
            case let .element(element) = representation.kind {

            if let elementURL = element.attribute(named: HTMLLinkAttribute.Href.rawValue)?.value.toString() {
               if let url = NSURL(string: elementURL) {
                   attributeValue = url
               } else {
                   attributeValue = elementURL
               }
            } else {
                attributeValue = NSURL(string: "")!
            }
            finalRepresentation = representation
        } else {

            // There's no support fora link representation that's not an HTML element, so this
            // scenario should only be possible if `representation == nil`.
            //
            assert(representation == nil)
            var attributes = [Attribute]()

            if let url = attributeValue as? URL {
                let urlValue = Attribute(name: HTMLLinkAttribute.Href.rawValue, value: .string(url.absoluteString))
                attributes.append(urlValue)
            }

            if let target = target {
                let targetValue = Attribute(name: HTMLLinkAttribute.target.rawValue, value: .string(target))
                attributes.append(targetValue)
            }

            let linkRepresentation = HTMLElementRepresentation(name: Element.a.rawValue, attributes: attributes)
            finalRepresentation = HTMLRepresentation(for: .element(linkRepresentation))
        }
        
        return super.apply(to: attributes, andStore: finalRepresentation)
    }
}
