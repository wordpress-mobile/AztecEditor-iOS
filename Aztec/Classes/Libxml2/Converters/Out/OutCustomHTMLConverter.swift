import Foundation
import libxml2

extension Libxml2.Out {

    class CustomHTMLConverter: Converter {

        typealias EditContext = Libxml2.EditContext
        typealias Node = Libxml2.Node
        typealias ElementNode = Libxml2.ElementNode
        typealias RootNode = Libxml2.RootNode
        typealias Attribute = Libxml2.Attribute
        typealias StringAttribute = Libxml2.StringAttribute
        typealias TextNode = Libxml2.TextNode
        typealias CommentNode = Libxml2.CommentNode

        required init() {
        }

        /// Converts the a Libxml2 Node into HTML representing the same data.
        ///
        /// - Parameters:
        ///     - rawNode: the Libxml2 Node to convert.
        ///
        /// - Returns: a String object representing the specified HTML data.
        ///
        func convert(_ rawNode: Node) -> String {

            let htmlDumpString = convertNode(rawNode)

            let finalString = htmlDumpString.replacingOccurrences(of: "<\(RootNode.name)>", with: "").replacingOccurrences(of: "</\(RootNode.name)>", with: "")
            
            return finalString
        }

        func convertNode(_ rawNode: Node) -> String {
            var output: String = ""

            switch rawNode {
            case let textNode as TextNode:
                output += convertTextNode(textNode)
            case let elementNode as ElementNode:
                output += convertElementNode(elementNode)
            case let commentNode as CommentNode:
                output += convertCommentNode(commentNode)
            default:
                fatalError("We're missing support for a node type.  This should not happen.")
            }

            return output
        }

        fileprivate func convertElementNode(_ rawNode: ElementNode) -> String {
            var output: String = ""
            var afterStartNode = ""
            var afterNode = ""
            if rawNode.isBlockLevelElement() {
                afterNode = "\n"
            }
            let name = rawNode.name
            output += "<\(name)"
            
            for rawAttribute in rawNode.attributes {
                output += " "
                if let stringAttribute = rawAttribute as? StringAttribute {
                    output += "\(stringAttribute.name)=\"\(stringAttribute.value)\""
                } else {
                    output += "\(rawAttribute.name)"
                }
            }

            if rawNode.children.isEmpty {
                output += "/>" + afterNode
                return output
            }
            if rawNode.isNodeType(.ul) || rawNode.isNodeType(.ol) {
                afterStartNode = "\n"
            }
            output += ">" + afterStartNode

            for child in rawNode.children {
                output += convertNode(child)
            }

            output += "</\(name)>" + afterNode

            return output
        }

        /// Creates a libxml2 element node from a HTML.TextNode.
        ///
        /// - Parameters:
        ///     - rawNode: the HTML.TextNode.
        ///
        /// - Returns: the libxml2 xmlNode
        ///
        fileprivate func convertTextNode(_ rawNode: TextNode) -> String {
            return rawNode.text()
        }

        /// Creates a libxml2 element node from a HTML.CommentNode.
        ///
        /// - Parameters:
        ///     - rawNode: the HTML.CommentNode.
        ///
        /// - Returns: the libxml2 xmlNode
        ///
        fileprivate func convertCommentNode(_ rawNode: CommentNode) -> String {
            return "<!--\(rawNode.comment)-->"
        }
    }
}
