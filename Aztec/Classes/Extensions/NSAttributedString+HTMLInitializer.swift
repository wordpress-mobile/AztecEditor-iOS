import Foundation
import UIKit

extension NSAttributedString {

    convenience init(withHTML html: String, usingDefaultFontDescriptor descriptor: UIFontDescriptor) {

        let htmlParser = HTMLParser()
        let rootNode = htmlParser.parse(html)

        let attributedStringComposer = AttributedStringComposer(usingDefaultFontDescriptor: descriptor)
        let attributedString = attributedStringComposer.compose(rootNode)

        self.init(attributedString: attributedString)
    }
}
