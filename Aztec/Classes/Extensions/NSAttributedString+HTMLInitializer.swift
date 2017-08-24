import Foundation
import UIKit

extension NSAttributedString {

    convenience init(withHTML html: String, usingDefaultFontDescriptor descriptor: UIFontDescriptor) {

        let htmlParser = HTMLParser()
        let rootNode = htmlParser.parse(html)

        let serializer = AttributedStringSerializer(usingDefaultFontDescriptor: descriptor)
        let attributedString = serializer.serialize(rootNode)

        self.init(attributedString: attributedString)
    }
}
