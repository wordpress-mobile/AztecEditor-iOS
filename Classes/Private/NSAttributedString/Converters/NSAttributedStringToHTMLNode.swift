import Foundation

class NSAttributedStringToHMTLNode: SafeConverter {
    typealias HTML = Libxml2.HTML
    typealias ElementNode = HTML.ElementNode
    typealias Node = HTML.Node
    typealias TextNode = HTML.TextNode

    func convert(string: NSAttributedString) -> Node {

        // The real conversion happens in real time during editing.  Nodes MUST be kept updated!

        let rootNode = string.rootNode()

        if rootNode.children.count == 0 {
            // No children at the root node means no post content.  An empty text node should do.
            //
            return TextNode(text: "")
        } else {
            return rootNode.children[0]
        }
    }
}
