import Foundation

class HTMLToAttributedString: Converter {

    typealias RootNode = Libxml2.RootNode

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
        let attributedString = nodeToAttributedString.convert(rootNode)

        return (rootNode, attributedString)
    }
}