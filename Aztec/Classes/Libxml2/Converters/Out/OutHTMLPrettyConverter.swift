import Foundation
import libxml2


// MARK: - HTML Prettifier!
//
extension Libxml2.Out {
    class HTMLPrettyConverter: Converter {

        typealias Attribute = Libxml2.Attribute
        typealias StringAttribute = Libxml2.StringAttribute
        typealias ElementNode = Libxml2.ElementNode
        typealias Node = Libxml2.Node
        typealias TextNode = Libxml2.TextNode
        typealias CommentNode = Libxml2.CommentNode
        typealias RootNode = Libxml2.RootNode



        // MARK: - Initializers

        init() {
            // No Op
        }

        ///
        ///
        func convert(_ rawNode: Node) -> String {
            return export(node: rawNode)
                .replacingOccurrences(of: "<\(RootNode.name)>", with: "")
                .replacingOccurrences(of: "</\(RootNode.name)>", with: "")
        }
    }
}


// MARK: - Export: Nodes
//
private extension Libxml2.Out.HTMLPrettyConverter {

    ///
    ///
    func export(node: Node) -> String {
        switch node {
        case let commentNode as CommentNode:
            return export(commentNode: commentNode)
        case let elementNode as ElementNode:
            return export(elementNode: elementNode)
        case let textNode as TextNode:
            return export(textNode: textNode)
        default:
            fatalError("We're missing support for a node type.  This should not happen.")
        }
    }

    ///
    ///
    private func export(commentNode node: CommentNode) -> String {
        return "<!--" + node.comment + "-->"
    }

    ///
    ///
    private func export(elementNode node: ElementNode) -> String {
        var attributes = ""
        for attribute in node.attributes {
            attributes += String(.space) + export(attribute: attribute)
        }

        var html = "<" + node.name + attributes + ">"
        guard !isVoidElementNode(elementNode: node) else {
            return html
        }

        for child in node.children {
            html += export(node: child)
        }

        html += "</" + node.name + ">"

        return html
    }

    ///
    ///
    private func export(textNode node: TextNode) -> String {
        return node.text().escapeHtmlEntities().encodeUnicodeCharactersAsHexadecimal()
    }

    ///
    ///
    private func isVoidElementNode(elementNode node: ElementNode) -> Bool {
        return Constants.voidElements.contains(node.name)
    }
}


// MARK: - Export: Attributes
//
private extension Libxml2.Out.HTMLPrettyConverter {

    ///
    ///
    func export(attribute: Attribute) -> String {
        switch attribute {
        case let stringAttribute as StringAttribute where !isBooleanAttribute(name: attribute.name):
            return export(stringAttribute: stringAttribute)
        default:
            return export(rawAttribute: attribute)
        }
    }

    ///
    ///
    private func export(stringAttribute attribute: StringAttribute) -> String {
        return attribute.name + "=\"" + attribute.value + "\""
    }

    ///
    ///
    private func export(rawAttribute: Attribute) -> String {
        return rawAttribute.name
    }

    /// HTMLTree.c // htmlIsBooleanAttr() // Used by htmlAttrDumpOutput
    ///
    private func isBooleanAttribute(name: String) -> Bool {
        return Constants.booleanAttributes.contains(name)
    }
}


// MARK: - Private
//
private extension Libxml2.Out.HTMLPrettyConverter {

    struct Constants {

        /// Ref. http://w3c.github.io/html/syntax.html#void-elements
        ///
        static let voidElements = ["area", "base", "br", "col", "embed", "hr", "img", "input", "link",
                                   "meta", "param", "source", "track", "wbr"]

        /// Ref. https://opensource.apple.com/tarballs/libxml2/libxml2-8.tar.gz
        ///
        static let booleanAttributes = ["checked", "compact", "declare", "defer", "disabled", "ismap",
                                        "multiple", "nohref", "noresize", "noshade", "nowrap", "readonly",
                                        "selected"]
    }
}
