import Foundation
import UIKit

class HTMLToAttributedString: Converter {

    typealias RootNode = Libxml2.RootNode
    typealias TextNode = Libxml2.TextNode
    typealias UndoRegistrationClosure = Libxml2.Node.UndoRegistrationClosure

    /// The default font descriptor that will be used as a base for conversions.
    ///
    let defaultFontDescriptor: UIFontDescriptor
    
    let registerUndo: UndoRegistrationClosure

    required init(usingDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor, registerUndo: @escaping UndoRegistrationClosure) {
        self.defaultFontDescriptor = defaultFontDescriptor
        self.registerUndo = registerUndo
    }

    func convert(_ html: String) throws -> (rootNode: RootNode, attributedString: NSAttributedString) {
        let htmlToNode = Libxml2.In.HTMLConverter(registerUndo: registerUndo)
        let nodeToAttributedString = HMTLNodeToNSAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor)

        let rootNode = try htmlToNode.convert(html)

        if rootNode.children.count == 0 {
            rootNode.append(TextNode(text: html, registerUndo: registerUndo))
        }

        let attributedString = nodeToAttributedString.convert(rootNode)

        return (rootNode, attributedString)
    }
}
