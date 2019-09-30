import UIKit

class UnderlineFormatter: StandardAttributeFormatter {

    init() {
        super.init(attributeKey: .underlineStyle,
                   attributeValue: NSUnderlineStyle.single.rawValue,
                   htmlRepresentationKey: .underlineHtmlRepresentation)
    }
}

class SpanUnderlineFormatter: UnderlineFormatter {

    override func apply(to attributes: [NSAttributedString.Key : Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key : Any] {

        let cssAttribute = CSSAttribute.underline
        let underlineStyleAttribute = Attribute(type: .style, value: .inlineCss([cssAttribute]))
        let spanRepresentation = HTMLElementRepresentation(ElementNode.init(type: .span, attributes: [underlineStyleAttribute], children: []))

        return super.apply(to: attributes, andStore: HTMLRepresentation(for: .element(spanRepresentation)))        
    }
}
