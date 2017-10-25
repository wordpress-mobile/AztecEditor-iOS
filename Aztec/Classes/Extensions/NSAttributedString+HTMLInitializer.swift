import Foundation
import UIKit

extension NSAttributedString {

    convenience init(
        withHTML html: String,
        defaultAttributes: [String: Any],
        postProcessingHTMLWith htmlTreeProcessor: HTMLTreeProcessor? = nil) {
        
        let htmlParser = HTMLParser()
        let rootNode = htmlParser.parse(html)
        let finalRootNode = htmlTreeProcessor?.process(rootNode) ?? rootNode
        
        let serializer = AttributedStringSerializer(defaultAttributes: defaultAttributes)
        let attributedString = serializer.serialize(finalRootNode)
        
        self.init(attributedString: attributedString)
    }
}
