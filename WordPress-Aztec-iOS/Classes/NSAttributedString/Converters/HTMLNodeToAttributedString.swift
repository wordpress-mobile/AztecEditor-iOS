import Foundation

class HMTLNodeToAttributedString: Converter {
    typealias HTML = Libxml2.HTML
    typealias ElementNode = HTML.ElementNode
    typealias Node = HTML.Node
    typealias TextNode = HTML.TextNode

    func convert(node: Node) -> NSAttributedString {

        if let textNode = node as? TextNode {
            return NSAttributedString(string: textNode.text)
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

        let tag = HTMLTag(name: elementNode.name)

        finalContent.addAttribute("HTMLTag", value: tag, range: NSRange(location: 0, length: finalContent.length))

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

        let tag = HTMLTag(name: elementNode.name)

        let placeholderContent: String

        if elementNode.name.lowercaseString == "br" {
            placeholderContent = "\n";
        } else {
            let objectReplacementCharacter = "\u{fffc}"

            placeholderContent = objectReplacementCharacter
        }

        return NSAttributedString(string: placeholderContent, attributes: ["HTMLTag": tag])
    }
}