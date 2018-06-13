import Foundation
import libxml2

protocol HTMLSerializerCustomizer {
    func converter(for element: ElementNode) -> ElementToTagConverter?
}

/// Composes the provided nodes into its HTML representation.
///
public class HTMLSerializer {
    
    /// Indentation Spaces to be applied
    ///
    let indentationSpaces: Int

    /// Converters
    private let genericElementConverter = GenericElementToTagConverter()
    
    private let customizer: HTMLSerializerCustomizer?
    
    /// Default Initializer
    ///
    /// - Parameters:
    ///     - indentationSpaces: Indicates the number of indentation spaces to be applied, per level.
    ///
    public init(indentationSpaces: Int = 2) {
        self.customizer = nil
        self.indentationSpaces = indentationSpaces
    }
    
    init(indentationSpaces: Int = 2, customizer: HTMLSerializerCustomizer? = nil) {
        self.customizer = customizer
        self.indentationSpaces = indentationSpaces
    }
    
    
    /// Serializes a node into its HTML representation
    ///
    public func serialize(_ node: Node, prettify: Bool = false) -> String {
        return serialize(node: node, prettify: prettify).trimmingCharacters(in: CharacterSet.newlines)
    }
    
    func serialize(_ nodes: [Node], prettify: Bool, level: Int = 0) -> String {
        return nodes.reduce("") { (previous, child) in
            return previous + serialize(node: child, prettify: prettify, level: level)
        }
    }
}


// MARK: - Nodes: Composition
//
private extension HTMLSerializer {
    
    /// Serializes a node into its HTML representation
    ///
    func serialize(node: Node, prettify: Bool, level: Int = 0) -> String {
        switch node {
        case let node as RootNode:
            return serialize(node, prettify: prettify)
        case let node as CommentNode:
            return serialize(node)
        case let node as ElementNode:
            return serialize(node, prettify: prettify, level: level)
        case let node as TextNode:
            return serialize(text: node)
        default:
            fatalError("We're missing support for a node type.  This should not happen.")
        }
    }
    
    
    /// Serializes a `RootNode` into its HTML representation
    ///
    private func serialize(_ rootNode: RootNode, prettify: Bool) -> String {
        return rootNode.children.reduce("") { (result, node) in
            return result + serialize(node: node, prettify: prettify)
        }
    }
    
    /// Serializes a `CommentNode` into its HTML representation
    ///
    private func serialize(_ commentNode: CommentNode) -> String {
        return "<!--" + commentNode.comment + "-->"
    }
    
    /// Serializes an `ElementNode` into its HTML representation
    ///
    private func serialize(_ elementNode: ElementNode, prettify: Bool, level: Int) -> String {
        let tag = converter(for: elementNode).convert(elementNode)
        
        let openingTagPrefix = self.openingTagPrefix(for: elementNode, prettify: prettify, level: level)
        let opening = openingTagPrefix + tag.opening
        
        let children = serialize(elementNode.children, prettify: prettify, level: level + 1)
        
        let closing: String
        
        if let closingTag = tag.closing {
            let prefix = self.closingTagPrefix(for: elementNode, prettify: prettify, withSpacesForIndentationLevel: level)
            let suffix = self.closingTagSuffix(for: elementNode, prettify: prettify)
            
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

private extension HTMLSerializer {
    /// Returns the Tag Prefix String at the specified level
    ///
    private func prefix(for level: Int) -> String {
        let indentation = level > 0 ? String(repeating: String(.space), count: level * indentationSpaces) : ""
        return String(.lineFeed) + indentation
    }
}

// MARK: - Opening Tag Affixes

private extension HTMLSerializer {
    
    private func openingTagPrefix(for elementNode: ElementNode, prettify: Bool, level: Int) -> String {
        guard requiresOpeningTagPrefix(elementNode, prettify: prettify) else {
            return ""
        }
        
        return prefix(for: level)
    }
    
    /// Required whenever the node is a blocklevel element
    ///
    private func requiresOpeningTagPrefix(_ node: ElementNode, prettify: Bool) -> Bool {
        return node.isBlockLevel() && prettify
    }
}

// MARK: - Closing Tag Affixes

private extension HTMLSerializer {
    
    private func closingTagPrefix(for elementNode: ElementNode, prettify: Bool, withSpacesForIndentationLevel level: Int) -> String {
        guard requiresClosingTagPrefix(elementNode, prettify: prettify) else {
            return ""
        }
        
        return prefix(for: level)
    }
    
    private func closingTagSuffix(for elementNode: ElementNode, prettify: Bool) -> String {
        guard prettify,
            requiresClosingTagSuffix(elementNode, prettify: prettify) else {
                return ""
        }
        
        return String(.lineFeed)
    }
    
    
    /// ClosingTag Prefix: Required whenever one of the children is a blocklevel element
    ///
    private func requiresClosingTagPrefix(_ node: ElementNode, prettify: Bool) -> Bool {
        guard prettify else {
            return false
        }
        
        return node.children.contains { child in
            let elementChild = child as? ElementNode
            return elementChild?.isBlockLevel() == true
        }
    }
    
    
    /// ClosingTag Suffix: Required whenever the node is blocklevel, and the right sibling is not
    ///
    private func requiresClosingTagSuffix(_ node: ElementNode, prettify: Bool) -> Bool {
        guard prettify,
            let rightSibling = node.rightSibling() else {
                return false
        }
        
        let rightElementNode = rightSibling as? ElementNode
        let isRightNodeRegularElement = rightElementNode == nil || rightElementNode?.isBlockLevel() == false
        
        return isRightNodeRegularElement && node.isBlockLevel()
    }
}

// MARK: - Element Conversion Logic

extension HTMLSerializer {
    private func converter(for elementNode: ElementNode) -> ElementToTagConverter {
        return customizer?.converter(for: elementNode) ?? genericElementConverter
    }
}
