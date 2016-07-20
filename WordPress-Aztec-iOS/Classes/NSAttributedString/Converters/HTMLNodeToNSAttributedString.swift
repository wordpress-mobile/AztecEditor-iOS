import Foundation

class HMTLNodeToNSAttributedString: SafeConverter {
    typealias HTML = Libxml2.HTML
    typealias ElementNode = HTML.ElementNode
    typealias Node = HTML.Node
    typealias TextNode = HTML.TextNode

    func convert(node: Node) -> NSAttributedString {

        if let textNode = node as? TextNode {
            return NSAttributedString(string: textNode.text, attributes: [keyForNode(textNode): textNode])
        } else {
            guard let elementNode = node as? ElementNode else {
                fatalError("Nodes can be either text or element nodes.")
            }

            if elementNode.children.count == 0 {
                return stringForEmptyNode(elementNode)
            } else {
                return stringForNode(elementNode)
            }
        }
    }

    /// Generates a unique ID for the specified node.
    ///
    private func keyForNode(node: Node) -> String {

        if node.name == Aztec.AttributeName.rootNode {
            return node.name
        } else {
            let uuid = NSUUID().UUIDString

            return "Aztec.HTMLTag.\(node.name).\(uuid)"
        }
    }

    /// Returns an attributed string representing the specified non-empty node.  Non-empty means
    /// the received node has children.
    ///
    /// - Parameters:
    ///     - elementNode: the element node to generate a representation string of.
    ///
    /// - Returns: the attributed string representing the specified element node.
    ///
    ///
    private func stringForNode(elementNode: ElementNode) -> NSAttributedString {
        assert(elementNode.children.count > 0)

        let finalContent = NSMutableAttributedString()

        for child in elementNode.children {
            let content = convert(child)

            finalContent.appendAttributedString(content)
        }

        finalContent.addAttribute(keyForNode(elementNode), value: elementNode, range: NSRange(location: 0, length: finalContent.length))

        return finalContent
    }

    /// Returns an attributed string representing the specified empty node.  Empty means the
    /// received node has no children.
    ///
    /// - Parameters:
    ///     - elementNode: the element node to generate a representation string of.
    ///
    /// - Returns: the attributed string representing the specified element node.
    ///
    private func stringForEmptyNode(elementNode: ElementNode) -> NSAttributedString {
        assert(elementNode.children.count == 0)

        let placeholderContent: String

        if elementNode.name.lowercaseString == "br" {
            placeholderContent = "\n";
        } else {
            let objectReplacementCharacter = "\u{fffc}"

            placeholderContent = objectReplacementCharacter
        }

        return NSAttributedString(string: placeholderContent, attributes: [keyForNode(elementNode): elementNode])
    }
}