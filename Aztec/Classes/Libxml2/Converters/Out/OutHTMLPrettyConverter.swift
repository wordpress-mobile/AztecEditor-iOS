import Foundation
import libxml2


// MARK: - HTML Prettifier!
//
extension Libxml2.Out {
    class HTMLPrettyConverter: Converter {

        // MARK: - Typealiases

        typealias Attribute         = Libxml2.Attribute
        typealias StringAttribute   = Libxml2.StringAttribute
        typealias ElementNode       = Libxml2.ElementNode
        typealias Node              = Libxml2.Node
        typealias TextNode          = Libxml2.TextNode
        typealias CommentNode       = Libxml2.CommentNode
        typealias RootNode          = Libxml2.RootNode

        /// Minimum Indentation Level to be effectively printed. Useful to avoid indenting everything under
        /// the Root Node.
        ///
        var minimumIndentationLevel = 1

        /// Indentation String to be applied
        ///
        var indentationString = "  "

        /// Indicates whether we want Pretty Print or not
        ///
        var prettyPrintEnabled = false


        // MARK: - Initializers

        init() {
            // No Op
        }

        /// Converts a Node into it's HTML String Representation
        ///
        func convert(_ rawNode: Node) -> String {
            return convert(node: rawNode)
                .replacingOccurrences(of: "<\(RootNode.name)>", with: "")
                .replacingOccurrences(of: "</\(RootNode.name)>", with: "")
                .trimmingCharacters(in: CharacterSet.newlines)
        }
    }
}


// MARK: - Export: Nodes
//
private extension Libxml2.Out.HTMLPrettyConverter {

    /// Serializes a Node into it's HTML String Representation
    ///
    func convert(node: Node, level: Int = 0) -> String {
        switch node {
        case let node as CommentNode:
            return convert(comment: node)
        case let node as ElementNode:
            return convert(element: node, level: level)
        case let node as TextNode:
            return convert(text: node)
        default:
            fatalError("We're missing support for a node type.  This should not happen.")
        }
    }

    /// Serializes a CommentNode into it's HTML String Representation
    ///
    private func convert(comment node: CommentNode) -> String {
        return "<!--" + node.comment + "-->"
    }

    /// Serializes an ElementNode into it's HTML String Representation
    ///
    private func convert(element node: ElementNode, level: Int) -> String {
        // Prefixes + Posfixes
        let indentForOpeningTag = requiresOpeningTagPrefix(node) ? indentationString(for: level) : ""
        let indentForClosingTag = requiresClosingTagPrefix(node) ? indentationString(for: level) : ""
        let prefixForOpeningTag = requiresOpeningTagPrefix(node) ? String(.newline) : ""
        let prefixForClosingTag = requiresClosingTagPrefix(node) ? String(.newline) : ""
        let posfixForClosingTag = requiresClosingTagPosfix(node) ? String(.newline) : ""

        // Serialize Attributes
        var attributes = ""
        for attribute in node.attributes {
            attributes += String(.space) + convert(attribute: attribute)
        }

        // Opening Tag
        var html = prefixForOpeningTag + indentForOpeningTag + "<" + node.name + attributes + ">"
        guard requiresClosingTag(node) else {
            return html
        }

        // Child Tags
        for child in node.children {
            html += convert(node: child, level: level + 1)
        }

        // Closing Tags
        html += prefixForClosingTag + indentForClosingTag + "</" + node.name + ">" + posfixForClosingTag

        return html
    }

    /// Returns the Indentation String for the specified level
    ///
    private func indentationString(for level: Int) -> String {
        guard level > minimumIndentationLevel else {
            return String()
        }

        return String(repeating: indentationString, count: (level - minimumIndentationLevel))
    }

    /// Serializes a TextNode into it's HTML String Representation
    ///
    private func convert(text node: TextNode) -> String {
        return node.text().encodeHtmlEntities()
    }

    /// OpeningTag Prefix: Required whenever the node is a blocklevel element
    ///
    private func requiresOpeningTagPrefix(_ node: ElementNode) -> Bool {
        return node.isBlockLevelElement() && prettyPrintEnabled
    }

    /// ClosingTag Prefix: Required whenever one of the children is a blocklevel element
    ///
    private func requiresClosingTagPrefix(_ node: ElementNode) -> Bool {
        return node.children.contains { child in
            let elementChild = child as? ElementNode
            return elementChild?.isBlockLevelElement() == true && prettyPrintEnabled
        }
    }

    /// ClosingTag Posfix: Required whenever the node is blocklevel, and the right sibling is not
    ///
    private func requiresClosingTagPosfix(_ node: ElementNode) -> Bool {
        guard let rightSibling = node.rightSibling() else {
            return false
        }

        return !rightSibling.isBlockLevelElement() && node.isBlockLevelElement() && prettyPrintEnabled
    }

    /// Indicates if an ElementNode is a Void Element (expected not to have a closing tag), or not.
    ///
    private func requiresClosingTag(_ node: ElementNode) -> Bool {
        return Constants.voidElements.contains(node.name) == false
    }
}


// MARK: - Print: Attributes
//
private extension Libxml2.Out.HTMLPrettyConverter {

    /// Serializes an Attribute into it's corresponding String Value, depending on the actual Attribute subclass.
    ///
    func convert(attribute: Attribute) -> String {
        switch attribute {
        case let stringAttribute as StringAttribute where !isBooleanAttribute(name: attribute.name):
            return convert(stringAttribute: stringAttribute)
        default:
            return convert(rawAttribute: attribute)
        }
    }

    /// Serializes a given StringAttribute.
    ///
    private func convert(stringAttribute attribute: StringAttribute) -> String {
        return attribute.name + "=\"" + attribute.value + "\""
    }

    /// Serializes a given Attribute
    ///
    private func convert(rawAttribute: Attribute) -> String {
        return rawAttribute.name
    }

    /// Indicates whether if an Attribute is expected to have a value, or not.
    ///
    private func isBooleanAttribute(name: String) -> Bool {
        return Constants.booleanAttributes.contains(name)
    }
}


// MARK: - Private Constants
//
private extension Libxml2.Out.HTMLPrettyConverter {

    struct Constants {

        /// List of 'Void Elements', that are expected *not* to have a closing tag.
        ///
        /// Ref. http://w3c.github.io/html/syntax.html#void-elements
        ///
        static let voidElements = ["area", "base", "br", "col", "embed", "hr", "img", "input", "link",
                                   "meta", "param", "source", "track", "wbr"]

        /// List of Boolean Attributes, that are not expected to have an actual value
        ///
        static let booleanAttributes = ["checked", "compact", "declare", "defer", "disabled", "ismap",
                                        "multiple", "nohref", "noresize", "noshade", "nowrap", "readonly",
                                        "selected"]
    }
}
