import Foundation


/// Composes the provided nodes into its HTML representation.
///
public class DefaultHTMLSerializer: HTMLSerializer {

    /// Indentation Spaces to be applied
    ///
    let indentationSpaces: Int

    /// Indicates whether we want Pretty Print or not
    ///
    let prettyPrint: Bool

    /// Default Initializer
    ///
    /// - Parameters:
    ///     - prettyPrint: Indicates whether if the output should be pretty-formatted, or not.
    ///     - indentationSpaces: Indicates the number of indentation spaces to be applied, per level.
    ///
    public init(prettyPrint: Bool = false, indentationSpaces: Int = 2) {
        self.indentationSpaces = indentationSpaces
        self.prettyPrint = prettyPrint
    }


    /// Serializes a node into its HTML representation
    ///
    public func serialize(_ node: Node) -> String {
        return serialize(node: node).trimmingCharacters(in: CharacterSet.newlines)
    }
}


// MARK: - Nodes: Composition
//
private extension DefaultHTMLSerializer {

    /// Serializes a node into its HTML representation
    ///
    func serialize(node: Node, level: Int = 0) -> String {
        switch node {
        case let node as RootNode:
            return serialize(root: node)
        case let node as CommentNode:
            return serialize(comment: node)
        case let node as ElementNode:
            return serialize(element: node, level: level)
        case let node as TextNode:
            return serialize(text: node)
        default:
            fatalError("We're missing support for a node type.  This should not happen.")
        }
    }


    /// Serializes a `RootNode` into its HTML representation
    ///
    private func serialize(root node: RootNode) -> String {
        return node.children.reduce("") { (result, node) in
            return result + serialize(node: node)
        }
    }

    /// Serializes a `CommentNode` into its HTML representation
    ///
    private func serialize(comment node: CommentNode) -> String {
        return "<!--" + node.comment + "-->"
    }

    /// Serializes an `ElementNode` into its HTML representation
    ///
    private func serialize(element node: ElementNode, level: Int) -> String {
        let opening = openingTag(for: node, at: level)

        guard let closing = closingTag(for: node, at: level) else {
            return opening
        }

        let children = node.children.reduce("") { (html, child)in
            return html + serialize(node: child, level: level + 1)
        }

        return opening + children + closing
    }

    /// Serializes an `TextNode` into its HTML representation
    ///
    private func serialize(text node: TextNode) -> String {
        return node.text().escapeHtmlNamedEntities()
    }
}



// MARK: - ElementNode: Helpers
//
private extension DefaultHTMLSerializer {

    /// Returns the Opening Tag for a given Element Node
    ///
    func openingTag(for node: ElementNode, at level: Int) -> String {
        let prefix = requiresOpeningTagPrefix(node) ? prefixForTag(at: level) : ""
        let attributes = serialize(attributes: node.attributes)

        return prefix + "<" + node.name + attributes + ">"
    }


    /// Returns the Closing Tag for a given Element Node, if its even required
    ///
    func closingTag(for node: ElementNode, at level: Int) -> String? {
        guard requiresClosingTag(node) else {
            return nil
        }

        let prefix = requiresClosingTagPrefix(node) ? prefixForTag(at: level) : ""
        let posfix = requiresClosingTagPosfix(node) ? posfixForTag() : ""

        return prefix + "</" + node.name + ">" + posfix
    }


    /// Returns the Tag Prefix String at the specified level
    ///
    private func prefixForTag(at level: Int) -> String {
        let indentation = level > 0 ? String(repeating: String(.space), count: level * indentationSpaces) : ""
        return String(.lineFeed) + indentation
    }


    /// Returns the Tag Posfix String
    ///
    private func posfixForTag() -> String {
        return String(.lineFeed)
    }


    /// OpeningTag Prefix: Required whenever the node is a blocklevel element
    ///
    private func requiresOpeningTagPrefix(_ node: ElementNode) -> Bool {
        return node.isBlockLevelElement() && prettyPrint
    }


    /// ClosingTag Prefix: Required whenever one of the children is a blocklevel element
    ///
    private func requiresClosingTagPrefix(_ node: ElementNode) -> Bool {
        return node.children.contains { child in
            let elementChild = child as? ElementNode
            return elementChild?.isBlockLevelElement() == true && prettyPrint
        }
    }


    /// ClosingTag Posfix: Required whenever the node is blocklevel, and the right sibling is not
    ///
    private func requiresClosingTagPosfix(_ node: ElementNode) -> Bool {
        guard let rightSibling = node.rightSibling() else {
            return false
        }

        let rightElementNode = rightSibling as? ElementNode
        let isRightNodeRegularElement = rightElementNode == nil || rightElementNode?.isBlockLevelElement() == false

        return isRightNodeRegularElement && node.isBlockLevelElement() && prettyPrint
    }


    /// Indicates if an ElementNode is a Void Element (expected not to have a closing tag), or not.
    ///
    private func requiresClosingTag(_ node: ElementNode) -> Bool {
        return Constants.voidElements.contains(node.name) == false
    }
}



// MARK: - Attributes: Serialization
//
private extension DefaultHTMLSerializer {

    /// Serializes an array of attributes into their HTML representation
    ///
    func serialize(attributes: [Attribute]) -> String {
        return attributes.reduce("") { (html, attribute) in
            return html + String(.space) + attribute.toString()
        }
    }
}



// MARK: - Private Constants
//
private extension DefaultHTMLSerializer {

    struct Constants {

        /// List of 'Void Elements', that are expected *not* to have a closing tag.
        ///
        /// Ref. http://w3c.github.io/html/syntax.html#void-elements
        ///
        static let voidElements = ["area", "base", "br", "col", "embed", "hr", "img", "input", "link",
                                   "meta", "param", "source", "track", "wbr"]
    }
}
