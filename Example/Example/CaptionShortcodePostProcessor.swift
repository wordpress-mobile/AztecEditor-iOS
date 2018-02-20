import Aztec
import Foundation


// MARK: - CaptionShortcodePostProcessor: Converts <figure><img><figcaption> structures into a [caption] shortcode.
//
class CaptionShortcodePostProcessor: HTMLProcessor {

    init() {
        super.init(tag: StandardElementType.figure.rawValue) { shortcode in
            guard let payload = shortcode.content else {
                return nil
            }

            /// Parse the Shortcode's Payload: We expect an [IMG, Figcaption]
            ///
            let parsed = HTMLParser().parse(payload)
            guard let imageContainerElement = parsed.firstChild(ofType: .img) ?? parsed.firstChild(ofType: .a),
                let figcaption = parsed.firstChild(ofType: .figcaption)
            else {
                return nil
            }

            /// Serialize the Caption's Shortcode!
            ///
            let serializer = DefaultHTMLSerializer()
            let attributes = shortcode.attributes.toString()
            let padding = attributes.isEmpty ? "" : " "

            var html = "[caption" + padding + attributes + "]"

            html += serializer.serialize(imageContainerElement)

            for child in figcaption.children {
                html += serializer.serialize(child)
            }

            html += "[/caption]"
            
            return html
        }
    }
}
