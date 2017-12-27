import Aztec
import Foundation


// MARK: - CaptionShortcodePreProcessor: Converts [caption] shortcode into a <figure><img><figcaption> structure.
//
class CaptionShortcodePreProcessor: ShortcodeProcessor {

    struct Constants {
        static let captionTag = "caption"
    }

    init() {
        super.init(tag: Constants.captionTag) { shortcode in
            guard let payloadText = shortcode.content else {
                return nil
            }

            /// Parse the Shortcode's Payload: We expect an [Img, Text, ...]
            ///
            let payloadNode = HTMLParser().parse(payloadText)
            guard let imageNode = payloadNode.firstChild(ofType: .img), payloadNode.children.count >= 2 else {
                return nil
            }

            /// Figcaption: Figure Children (minus) the image
            ///
            var caption = Set(payloadNode.children)
            caption.remove(imageNode)

            let figcaptionNode = ElementNode(type: .figcaption, attributes: [], children: Array(caption))

            /// Figure: Image + Figcaption! Woo!
            ///
            let figure = ElementNode(type: .figure, attributes: [], children: [imageNode, figcaptionNode])

            /// Final Step: Serialize back to string.
            /// This is expected to produce a `<figure><img<figcaption/></figure>` snippet.
            ///
            let serializer = DefaultHTMLSerializer()
            return serializer.serialize(figure)
        }
    }
}
