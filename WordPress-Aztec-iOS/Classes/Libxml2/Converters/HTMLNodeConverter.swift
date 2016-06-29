import Foundation
import libxml2

extension Libxml2 {
    class HTMLNodeConverter: Converter {

        typealias Node = HTML.Node
        typealias TextNode = HTML.TextNode

        typealias TypeIn = xmlNode
        typealias TypeOut = Node

        /// Converts a single node (from libxml2) into an HTML.Node.
        ///
        /// - Parameters:
        ///     - attributes: the libxml2 attribute to convert.
        ///
        /// - Returns: an HTML.Node.
        ///
        func convert(rawNode: xmlNode) -> Node {
            var node: Node!
            let nodeName = getNodeName(rawNode)

            if nodeName.lowercaseString == "text" {
                node = createTextNode(rawNode)
            } else {
                node = createGenericNode(rawNode)
            }

            let attributesConverter = HTMLAttributesConverter()
            let attributes = attributesConverter.convert(rawNode.properties)
            node.append(attributes: attributes)

            return node
        }

        /// Converts a generic libxml2 xmlNode into a HTML.Node.
        ///
        /// - Parameters:
        ///     - rawNode: the libxml2 xmlNode.
        ///
        /// - Returns: the HTML.Node
        ///
        private func createGenericNode(rawNode: xmlNode) -> Node {
            let nodeName = getNodeName(rawNode)
            var childNode: Node?

            if rawNode.children != nil {
                childNode = convert(rawNode.children.memory)
            }

            let node = Node(name: nodeName, child: childNode)

            return node
        }

        private func createTextNode(rawNode: xmlNode) -> TextNode {
            let nodeName = getNodeName(rawNode)
            let text = String(CString: UnsafePointer<Int8>(rawNode.content), encoding: NSUTF8StringEncoding)!
            let node = TextNode(name: nodeName, child: nil, text: text)

            return node
        }

        private func getNodeName(rawNode: xmlNode) -> String {
            return String(CString: UnsafePointer<Int8>(rawNode.name), encoding: NSUTF8StringEncoding)!
        }
    }
}