import Foundation
import UIKit

class HTMLToAttributedString: SafeConverter {

    typealias RootNode = Libxml2.RootNode
    typealias TextNode = Libxml2.TextNode

    /// The default font descriptor that will be used as a base for conversions.
    ///
    let defaultFontDescriptor: UIFontDescriptor

    required init(usingDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) {
        self.defaultFontDescriptor = defaultFontDescriptor
    }

    func convert(_ html: String) -> (rootNode: RootNode, attributedString: NSAttributedString) {
        let htmlToNode = Libxml2.In.HTMLConverter()
        let nodeToAttributedString = HTMLNodeToNSAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor)

        let rootNode = htmlToNode.convert(html)

        if rootNode.children.count == 0 {
            rootNode.children.append(TextNode(text: html))
        }

        let attributedString = nodeToAttributedString.convert(rootNode)

        return (rootNode, attributedString)
    }
}
