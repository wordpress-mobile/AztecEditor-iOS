import Aztec
import Foundation

/// Converts <figure><img><figcaption> structures into a [caption] shortcode.
///
class CaptionShortcodeOutputProcessor: HTMLProcessor {

    init() {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        super.init(for: "figure") { element in
            guard let payload = element.content else {
                return nil
            }

            /// Parse the Shortcode's Payload: We expect an [IMG, Figcaption]
            ///
            let rootNode = HTMLParser().parse(payload)
            
            guard let coreNode = rootNode.firstChild(ofType: .img) ?? rootNode.firstChild(ofType: .a),
                let figcaption = rootNode.firstChild(ofType: .figcaption)
            else {
                return nil
            }

            /// Serialize the Caption's Shortcode!
            ///
            let serializer = HTMLSerializer()
            var attributes = element.attributes
            var imgNode: ElementNode?

            // Find img child node of caption
            if coreNode.isNodeType(.img) {
                imgNode = coreNode
            } else {
                imgNode = coreNode.firstChild(ofType: .img)
            }

            if let imgNode = imgNode {
                attributes = CaptionShortcodeOutputProcessor.attributes(from: imgNode, basedOn: attributes)
            }
            
            if !attributes.contains(where: { $0.key == "id" }) {
                attributes.insert(ShortcodeAttribute(key: "id", value: ""), at: 0)
            }
            
            let attributesHTMLRepresentation = shortcodeAttributeSerializer.serialize(attributes)

            var html = "[caption " + attributesHTMLRepresentation + "]"

            html += serializer.serialize(coreNode)

            for child in figcaption.children {
                html += serializer.serialize(child)
            }

            html += "[/caption]"
            
            return html
        }
    }

    static func attributes(from imgNode: ElementNode, basedOn baseAttributes: [ShortcodeAttribute]) -> [ShortcodeAttribute] {
        var captionAttributes = baseAttributes
        let imgAttributes = imgNode.attributes
        
        for attribute in imgAttributes {
            guard attribute.type != .src,
                let attributeValue = attribute.value.toString() else {
                    continue
            }

            if attribute.type == .class {
                let classAttributes = attributeValue.components(separatedBy: " ")
                for classAttribute in classAttributes {
                    if classAttribute.hasPrefix("wp-image-") {
                        let value = classAttribute.replacingOccurrences(of: "wp-image-", with: "attachment_")
                        
                        captionAttributes.set(value, forKey: "id")
                    } else if classAttribute.hasPrefix("align"){
                        captionAttributes.set(classAttribute, forKey: "align")
                    }
                }
            } else {
                captionAttributes.set(attributeValue, forKey: attribute.name)
            }
        }
        
        return captionAttributes
    }
}
