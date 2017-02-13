import Foundation
import UIKit

class HTMLToAttributedString: Converter {

    typealias EditContext = Libxml2.EditContext
    typealias RootNode = Libxml2.RootNode
    typealias TextNode = Libxml2.TextNode

    /// The default font descriptor that will be used as a base for conversions.
    ///
    let defaultFontDescriptor: UIFontDescriptor
    
    let editContext: EditContext?

    required init(usingDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor, editContext: EditContext? = nil) {
        self.defaultFontDescriptor = defaultFontDescriptor
        self.editContext = editContext
    }

    func convert(_ html: String) throws -> (rootNode: RootNode, attributedString: NSAttributedString) {
        let htmlToNode = Libxml2.In.HTMLConverter(editContext: editContext)
        let nodeToAttributedString = HMTLNodeToNSAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor)

        let rootNode = try htmlToNode.convert(html)

        if rootNode.children.count == 0 {
            rootNode.append(TextNode(text: html, editContext: editContext))
        }

        let attributedString = nodeToAttributedString.convert(rootNode)

        return (rootNode, attributedString)
    }
}
