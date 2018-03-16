import Foundation
import UIKit

extension NSAttributedString {
    
    typealias CaptionStyler = AttributedStringSerializer.CaptionStyler
    
    convenience init(
        withHTML html: String,
        defaultAttributes: [NSAttributedStringKey: Any],
        captionStyler: @escaping CaptionStyler,
        postProcessingHTMLWith htmlTreeProcessor: HTMLTreeProcessor? = nil) {
        
        let htmlParser = HTMLParser()
        let rootNode = htmlParser.parse(html)
        
        htmlTreeProcessor?.process(rootNode)
        
        let serializer = AttributedStringSerializer(defaultAttributes: defaultAttributes, captionStyler: captionStyler)
        let attributedString = serializer.serialize(rootNode)
        
        self.init(attributedString: attributedString)
    }
}
