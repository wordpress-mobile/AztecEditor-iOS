import Foundation
import UIKit

extension NSAttributedString {

    convenience init(withHTML html: String, defaultAttributes: [String: Any]) {

        let htmlParser = HTMLParser()
        let rootNode = htmlParser.parse(html)

        let serializer = AttributedStringSerializer(defaultAttributes: defaultAttributes)
        let attributedString = serializer.serialize(rootNode)

        self.init(attributedString: attributedString)
    }
}
