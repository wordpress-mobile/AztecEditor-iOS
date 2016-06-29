import Foundation
import libxml2

extension Libxml2 {
    class RawNodeToNode: Converter {

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
            let node = createNode(rawNode)

            let attributesConverter = HTMLAttributesConverter()
            let attributes = attributesConverter.convert(rawNode.properties)
            node.append(attributes: attributes)

            return node
        }

        private func createNode(rawNode: xmlNode) -> Node {
            let nodeName = getNodeName(rawNode)

            if nodeName.lowercaseString == "text" {
                return createTextNode(rawNode)
            } else {
                return createGenericNode(rawNode)
            }
        }

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