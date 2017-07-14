import UIKit

class LinkFormatter: StandardAttributeFormatter {
    static let htmlRepresentationKey = "Link.htmlRepresentation"

    init() {
        super.init(attributeKey: NSLinkAttributeName,
                   attributeValue: NSURL(string:"")!,
                   htmlRepresentationKey: LinkFormatter.htmlRepresentationKey)
    }

    override func apply(to attributes: [String : Any], andStore representation: HTMLRepresentation?) -> [String: Any] {

        var updatedAttributes = attributes

        if let representation = representation,
            case let .element(element) = representation {

            let linkURL: NSURL

            if let elementUrl = element.attribute(named: HTMLLinkAttribute.Href.rawValue)?.value.toString() {
                linkURL = NSURL(string: elementUrl)!
            } else {
                linkURL = NSURL(string: "")!
            }

            attributeValue = linkURL
        } else {

            // There's no support fora link representation that's not an HTML element, so this
            // scenario should only be possible if `representation == nil`.
            //
            assert(representation == nil)
        }

        updatedAttributes = addUnderlineInLink(attributes: attributes)

        return super.apply(to: updatedAttributes, andStore: representation)
    }
}


extension LinkFormatter{

    /// Create underline link to the designated string with existing attributes.
    ///
    /// - Parameters:
    ///     - attributes: Existing atributes for formatting.
    ///

    internal func addUnderlineInLink(attributes:[String: Any]?) -> [String: Any]{
        guard let attrbutes = attributes else{
            return ["":""]
        }
        var modifiedAttributes : [String : Any] = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        for (attributeKey, attributeValue) in attrbutes{
            modifiedAttributes[attributeKey] = attributeValue
        }
        return modifiedAttributes
    }

    /// Remove underline from URL link
    ///
    /// - Parameters:
    ///     - attributes: Existing atributes for formatting.
    ///

    internal func removeUnderlineInLink(attributes:[String: Any]?) -> [String: Any]{
        guard let attrbutes = attributes else{
            return ["":""]
        }
        var modifiedAttributes = attrbutes
        modifiedAttributes.removeValue(forKey: NSUnderlineStyleAttributeName)
        return modifiedAttributes
    }

}
