import Foundation
import libxml2


// MARK: - HTML Prettifier!
//
extension Libxml2.Out {
    class HTMLConverter: Converter {

        // MARK: - Typealiases

        typealias Attribute         = Libxml2.Attribute
        typealias StringAttribute   = Libxml2.StringAttribute
        typealias ElementNode       = Libxml2.ElementNode
        typealias Node              = Libxml2.Node
        typealias TextNode          = Libxml2.TextNode
        typealias CommentNode       = Libxml2.CommentNode
        typealias RootNode          = Libxml2.RootNode

        /// Indentation Spaces to be applied
        ///
        let indentationSpaces: Int

        /// Indicates whether we want Pretty Print or not
        ///
        let prettyPrint: Bool

        let inspector = Libxml2.DOMInspector()

        /// Default Initializer
        ///
        /// - Parameters:
        ///     - prettyPrint: Indicates whether if the output should be pretty-formatted, or not.
        ///     - indentationSpaces: Indicates the number of indentation spaces to be applied, per level.
        ///
        init(prettyPrint: Bool = false, indentationSpaces: Int = 2) {
            self.indentationSpaces = indentationSpaces
            self.prettyPrint = prettyPrint
        }


        /// Converts a Node into it's HTML String Representation
        ///
        func convert(_ rawNode: Node) -> String {
            return convert(node: rawNode).trimmingCharacters(in: CharacterSet.newlines)
        }
    }
}


// MARK: - Nodes: Serialization
//
private extension Libxml2.Out.HTMLConverter {

    /// Serializes a Node into it's HTML String Representation
    ///
    func convert(node: Node, level: Int = 0) -> String {
        switch node {
        case let node as RootNode:
            return convert(root: node)
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


    /// Serializes a RootNode into it's HTML String Representation
    ///
    private func convert(root node: RootNode) -> String {
        return node.children.reduce("") { (result, node) in
            return result + convert(node: node)
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
        let opening = openingTag(for: node, at: level)

        guard let closing = closingTag(for: node, at: level) else {
            return opening
        }

        let children = node.children.reduce("") { (html, child)in
            return html + convert(node: child, level: level + 1)
        }

        return opening + children + closing
    }


    /// Serializes a TextNode into it's HTML String Representation
    ///
    private func convert(text node: TextNode) -> String {
        return inspector.text(for: node).encodeHtmlEntities()
    }
}



// MARK: - ElementNode: Tags
//
private extension Libxml2.Out.HTMLConverter {

    /// Returns the Opening Tag for a given Element Node
    ///
    func openingTag(for node: ElementNode, at level: Int) -> String {
        let prefix = requiresOpeningTagPrefix(node) ? prefixForTag(at: level) : ""
        let attributes = convert(attributes: node.attributes)

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
        return String(.newline) + indentation
    }


    /// Returns the Tag Posfix String
    ///
    private func posfixForTag() -> String {
        return String(.newline)
    }


    /// OpeningTag Prefix: Required whenever the node is a blocklevel element
    ///
    private func requiresOpeningTagPrefix(_ node: ElementNode) -> Bool {
        return inspector.isBlockLevelElement(node) && prettyPrint
    }


    /// ClosingTag Prefix: Required whenever one of the children is a blocklevel element
    ///
    private func requiresClosingTagPrefix(_ node: ElementNode) -> Bool {
        return node.children.contains { child in
            guard let elementChild = child as? ElementNode else {
                return false
            }

            return inspector.isBlockLevelElement(elementChild) == true && prettyPrint
        }
    }


    /// ClosingTag Posfix: Required whenever the node is blocklevel, and the right sibling is not
    ///
    private func requiresClosingTagPosfix(_ node: ElementNode) -> Bool {

        guard let rightSiblingElement = inspector.rightSibling(of: node) as? ElementNode else {
            return false
        }

        return !inspector.isBlockLevelElement(rightSiblingElement) && inspector.isBlockLevelElement(node) && prettyPrint
    }


    /// Indicates if an ElementNode is a Void Element (expected not to have a closing tag), or not.
    ///
    private func requiresClosingTag(_ node: ElementNode) -> Bool {
        return Constants.voidElements.contains(node.name) == false
    }
}



// MARK: - Attributes: Serialization
//
private extension Libxml2.Out.HTMLConverter {

    /// Serializes a collection of Attributes into their HTML Form
    ///
    func convert(attributes: [Attribute]) -> String {
        return attributes.reduce("") { (html, attribute) in
            return html + String(.space) + convert(attribute: attribute)
        }
    }


    /// Serializes an Attribute into it's corresponding String Value, depending on the actual Attribute subclass.
    ///
    private func convert(attribute: Attribute) -> String {
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
private extension Libxml2.Out.HTMLConverter {

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
