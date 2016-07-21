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
        func convert(rawNode: Node) -> xmlNode {
            var node: xmlNode!
            let nodeName = rawNode.name
            
            if let textNode = rawNode as? TextNode {
                node = createTextNode(textNode)
            } else  {
                //node = createElementNode(rawNode)
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
//        private func createElementNode(rawNode: Node) -> xmlNode {
//            let nodeName = getNodeName(rawNode)
//            var children = [Node]()
//
//            if rawNode.children != nil {
//                let nodesConverter = NodesConverter()
//                children.appendContentsOf(nodesConverter.convert(rawNode.children))
//            }
//
//            let attributes = createAttributes(fromNode: rawNode)
//            let node = ElementNode(name: nodeName, attributes: attributes, children: children)
//
//            return node
//        }

        /// Creates a libxml2 element node from a HTML.TextNode.
        ///
        /// - Parameters:
        ///     - rawNode: the HTML.TextNode.
        ///
        /// - Returns: the libxml2 xmlNode
        ///
        private func createTextNode(rawNode: TextNode) -> xmlNode {
            
            let name = "text"
            let nameCStr = name.cStringUsingEncoding(NSUTF8StringEncoding)!
            let namePtr = UnsafePointer<xmlChar>(nameCStr)
            
            let value = rawNode.text
            let valueCStr = value.cStringUsingEncoding(NSUTF8StringEncoding)!
            let valuePtr = UnsafeMutablePointer<xmlChar>(valueCStr)
            
            //let attributes = Libxml2.Out.AttributeConverter().convert(rawNode.attributes)
            
            var node = xmlNode()
            node.name = namePtr
            node.content = valuePtr

            return node
        }
    }
}