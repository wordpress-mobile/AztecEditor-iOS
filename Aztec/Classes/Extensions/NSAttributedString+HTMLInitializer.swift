import Foundation
import UIKit

extension NSAttributedString {

    convenience init(
        withHTML html: String,
        defaultAttributes: [AttributedStringKey: Any],
        postProcessingHTMLWith htmlTreeProcessor: HTMLTreeProcessor? = nil) {
        
        let htmlParser = HTMLParser()
        let rootNode = htmlParser.parse(html)
        
        htmlTreeProcessor?.process(rootNode)
        
        let serializer = AttributedStringSerializer(defaultAttributes: defaultAttributes)
        let attributedString = serializer.serialize(rootNode)
        
        self.init(attributedString: attributedString)
    }
}
