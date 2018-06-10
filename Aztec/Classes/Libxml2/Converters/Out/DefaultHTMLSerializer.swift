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
    
    /// Converters
    private let genericElementConverter = GenericElementToTagConverter()

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
    
    public func serialize(_ nodes: [Node], level: Int = 0) -> String {
        return nodes.reduce("") { (previous, child) in
            return previous + serialize(node: child, level: level)
        }
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
            return serialize(node)
        case let node as CommentNode:
            return serialize(node)
        case let node as ElementNode:
            return serialize(node, level: level)
        case let node as TextNode:
            return serialize(text: node)
        default:
            fatalError("We're missing support for a node type.  This should not happen.")
        }
    }


    /// Serializes a `RootNode` into its HTML representation
    ///
    private func serialize(_ rootNode: RootNode) -> String {
        return rootNode.children.reduce("") { (result, node) in
            return result + serialize(node: node)
        }
    }

    /// Serializes a `CommentNode` into its HTML representation
    ///
    private func serialize(_ commentNode: CommentNode) -> String {
        return "<!--" + commentNode.comment + "-->"
    }

    /// Serializes an `ElementNode` into its HTML representation
    ///
    private func serialize(_ elementNode: ElementNode, level: Int) -> String {
        let tag = genericElementConverter.convert(elementNode)
        
        let openingTagPrefix = self.openingTagPrefix(for: elementNode, withSpacesForIndentationLevel: level)
        let opening = openingTagPrefix + tag.opening
        
        let children = serialize(elementNode.children, level: level + 1)
        
        let closing: String
        
        if let closingTag = tag.closing {
            let prefix = self.closingTagPrefix(for: elementNode, withSpacesForIndentationLevel: level)
            let suffix = self.closingTagSuffix(for: elementNode)
            
            closing = prefix + closingTag + suffix
        } else {
            closing = ""
        }

        return opening + children + closing
    }

    /// Serializes an `TextNode` into its HTML representation
    ///
    private func serialize(text node: TextNode) -> String {
        return node.text().escapeHtmlNamedEntities()
    }
}

// MARK: - Indentation & newlines

private extension DefaultHTMLSerializer {
    /// Returns the Tag Prefix String at the specified level
    ///
    private func prefix(for level: Int) -> String {
        let indentation = level > 0 ? String(repeating: String(.space), count: level * indentationSpaces) : ""
        return String(.lineFeed) + indentation
    }
}

// MARK: - Opening Tag Affixes

private extension DefaultHTMLSerializer {

    private func openingTagPrefix(for elementNode: ElementNode, withSpacesForIndentationLevel level: Int) -> String {
        guard requiresOpeningTagPrefix(elementNode) else {
            return ""
        }
        
        return prefix(for: level)
    }

    /// Required whenever the node is a blocklevel element
    ///
    private func requiresOpeningTagPrefix(_ node: ElementNode) -> Bool {
        return node.isBlockLevel() && prettyPrint
    }
}

// MARK: - Closing Tag Affixes

private extension DefaultHTMLSerializer {
    
    private func closingTagPrefix(for elementNode: ElementNode,  withSpacesForIndentationLevel level: Int) -> String {
        guard requiresClosingTagPrefix(elementNode) else {
            return ""
        }
        
        return prefix(for: level)
    }
    
    private func closingTagSuffix(for elementNode: ElementNode) -> String {
        guard requiresClosingTagSuffix(elementNode) else {
            return ""
        }
        
        return String(.lineFeed)
    }


    /// ClosingTag Prefix: Required whenever one of the children is a blocklevel element
    ///
    private func requiresClosingTagPrefix(_ node: ElementNode) -> Bool {
        return node.children.contains { child in
            let elementChild = child as? ElementNode
            return elementChild?.isBlockLevel() == true && prettyPrint
        }
    }


    /// ClosingTag Suffix: Required whenever the node is blocklevel, and the right sibling is not
    ///
    private func requiresClosingTagSuffix(_ node: ElementNode) -> Bool {
        guard let rightSibling = node.rightSibling() else {
            return false
        }

        let rightElementNode = rightSibling as? ElementNode
        let isRightNodeRegularElement = rightElementNode == nil || rightElementNode?.isBlockLevel() == false

        return isRightNodeRegularElement && node.isBlockLevel() && prettyPrint
    }
}
