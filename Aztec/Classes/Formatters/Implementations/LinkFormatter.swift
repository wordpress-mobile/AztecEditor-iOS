import UIKit

class LinkFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .link,
                   attributeValue: NSURL(string:"")!,
                   htmlRepresentationKey: .linkHtmlRepresentation)
    }

    override func apply(to attributes: [AttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [AttributedStringKey: Any] {

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
        } else {

            // There's no support fora link representation that's not an HTML element, so this
            // scenario should only be possible if `representation == nil`.
            //
            assert(representation == nil)
        }
        
        return super.apply(to: attributes, andStore: representation)
    }
}
