import Foundation
import libxml2

extension Libxml2.Out {
    class NodeConverter: Converter {

        typealias Attribute = HTML.Attribute
        typealias ElementNode = HTML.ElementNode
        typealias Node = HTML.Node
        typealias TextNode = HTML.TextNode

        /// Converts a single HTML.Node into a libxml2 node
        ///
        /// - Parameters:
        ///     - attributes: the HTML.Node convert.
        ///
        /// - Returns: a libxml2 node.
        ///
        func convert(rawNode: Node) -> UnsafeMutablePointer<xmlNode> {
            var node: UnsafeMutablePointer<xmlNode>!
            let nodeName = rawNode.name
            
            if let textNode = rawNode as? TextNode {
                node = createTextNode(textNode)
            } else if let elementNode = rawNode as? ElementNode {
                node = createElementNode(elementNode)
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
        private func createElementNode(rawNode: ElementNode) -> UnsafeMutablePointer<xmlNode> {
            let nodeConverter = NodeConverter()
            
            let name = rawNode.name
            let nameCStr = name.cStringUsingEncoding(NSUTF8StringEncoding)!
            let namePtr = UnsafeMutablePointer<xmlChar>(nameCStr)
            
            let node = xmlNewNode(nil, namePtr)
            
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
        private func createTextNode(rawNode: TextNode) -> UnsafeMutablePointer<xmlNode> {
            let value = rawNode.text
            let valueCStr = value.cStringUsingEncoding(NSUTF8StringEncoding)!
            let valuePtr = UnsafeMutablePointer<xmlChar>(valueCStr)
            
            return xmlNewText(valuePtr)
        }
    }
}