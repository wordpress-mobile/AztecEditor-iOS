import Foundation

class HTMLToAttributedString: Converter {

    typealias RootNode = Libxml2.RootNode
    typealias TextNode = Libxml2.TextNode

    /// The default font descriptor that will be used as a base for conversions.
    ///
    let defaultFontDescriptor: UIFontDescriptor

    required init(usingDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) {
        self.defaultFontDescriptor = defaultFontDescriptor
    }

    func convert(html: String) throws -> (rootNode: RootNode, attributedString: NSAttributedString) {
        let htmlToNode = Libxml2.In.HTMLConverter()
        let nodeToAttributedString = HMTLNodeToNSAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor)

        let rootNode = try htmlToNode.convert(html)

        if rootNode.children.count == 0 {
            rootNode.append(TextNode(text: html))
        }

        let attributedString = nodeToAttributedString.convert(rootNode)

        return (rootNode, attributedString)
    }
}