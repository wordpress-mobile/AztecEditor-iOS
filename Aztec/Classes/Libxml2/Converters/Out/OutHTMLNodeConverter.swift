import Foundation
import libxml2

extension Libxml2.Out {
    class NodeConverter: Converter {

        typealias Attribute = Libxml2.Attribute
        typealias ElementNode = Libxml2.ElementNode
        typealias Node = Libxml2.Node
        typealias TextNode = Libxml2.TextNode
        typealias CommentNode = Libxml2.CommentNode

        /// Converts a single HTML.Node into a libxml2 node
        ///
        /// - Parameters:
        ///     - attributes: the HTML.Node convert.
        ///
        /// - Returns: a libxml2 node.
        ///
        func convert(_ rawNode: Node) -> xmlNodePtr {
            var node: xmlNodePtr
            
            if let textNode = rawNode as? TextNode {
                node = createTextNode(textNode)
            } else if let elementNode = rawNode as? ElementNode {
                node = createElementNode(elementNode)
            } else if let commentNode = rawNode as? CommentNode {
                node = createCommentNode(commentNode)
            } else {
                fatalError("We're missing support for a node type.  This should not happen.")
            }

            return node
        }

        /// Creates a libxml2 element node from a HTML.Node
        ///
        /// - Parameters:
        ///     - rawNode: HTML.ElementNode
        ///
        /// - Returns: the the libxml2 xmlNode.
        ///
        fileprivate func createElementNode(_ rawNode: ElementNode) -> xmlNodePtr {
            let nodeConverter = NodeConverter()
            
            let name = rawNode.name
            let nameCStr = name.cString(using: String.Encoding.utf8)!
            let namePtr = UnsafePointer<xmlChar>(OpaquePointer(nameCStr))
            
            let node = xmlNewNode(nil, namePtr)!
            let attributeConverter = AttributeConverter(forNode: node)

            for rawAttribute in rawNode.attributes {
                let _ = attributeConverter.convert(rawAttribute)
            }
            
            for child in rawNode.children {
                let childNode = nodeConverter.convert(child)
                xmlAddChild(node, childNode)
            }
            
            return node
        }

        /// Creates a libxml2 element node from a HTML.TextNode.
        ///
        /// - Parameters:
        ///     - rawNode: the HTML.TextNode.
        ///
        /// - Returns: the libxml2 xmlNode
        ///
        fileprivate func createTextNode(_ rawNode: TextNode) -> xmlNodePtr {
            let value = rawNode.text()
            let valueCStr = value.cString(using: String.Encoding.utf8)!
            let valuePtr = UnsafePointer<xmlChar>(OpaquePointer(valueCStr))
            
            return xmlNewText(valuePtr)
        }

        /// Creates a libxml2 element node from a HTML.CommentNode.
        ///
        /// - Parameters:
        ///     - rawNode: the HTML.CommentNode.
        ///
        /// - Returns: the libxml2 xmlNode
        ///
        fileprivate func createCommentNode(_ rawNode: CommentNode) -> xmlNodePtr {
            let value = rawNode.comment
            let valueCStr = value.cString(using: String.Encoding.utf8)!
            let valuePtr = UnsafePointer<xmlChar>(OpaquePointer(valueCStr))

            return xmlNewComment(valuePtr)
        }
    }
}
