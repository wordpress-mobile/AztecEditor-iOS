import Foundation
import libxml2

extension Libxml2.In {
    class NodeConverter: SafeConverter {

        typealias Attribute = Libxml2.Attribute
        typealias ElementNode = Libxml2.ElementNode
        typealias Node = Libxml2.Node
        typealias RootNode = Libxml2.RootNode
        typealias TextNode = Libxml2.TextNode
        typealias CommentNode = Libxml2.CommentNode
        
        /// Converts a single node (from libxml2) into an HTML.Node.
        ///
        /// - Parameters:
        ///     - attributes: the libxml2 attribute to convert.
        ///
        /// - Returns: an HTML.Node.
        ///
        func convert(rawNode: xmlNode) -> Node {
            var node: Node

            switch rawNode.type {
            case XML_TEXT_NODE:
                node = createTextNode(rawNode)
            case XML_COMMENT_NODE:
                node = createCommentNode(rawNode)
            default:
                node = createElementNode(rawNode)
            }

            return node
        }

        private func createAttributes(fromNode rawNode: xmlNode) -> [Attribute] {
            let attributesConverter = AttributesConverter()
            return attributesConverter.convert(rawNode.properties)
        }

        /// Creates an HTML.Node from a libxml2 element node.
        ///
        /// - Parameters:
        ///     - rawNode: the libxml2 xmlNode.
        ///
        /// - Returns: the HTML.ElementNode
        ///
        private func createElementNode(rawNode: xmlNode) -> ElementNode {

            let nodeName = getNodeName(rawNode)

            switch nodeName.lowercaseString {
            case RootNode.name:
                return createRootNode(rawNode)
            default:
                break
            }

            var children = [Node]()

            if rawNode.children != nil {
                let nodesConverter = NodesConverter()
                children.appendContentsOf(nodesConverter.convert(rawNode.children))
            }

            let attributes = createAttributes(fromNode: rawNode)
            let node = ElementNode(name: nodeName, attributes: attributes, children: children)

            // TODO: This can be optimized to be set during instantiation of the child nodes.
            //
            for child in children {
                child.parent = node
            }

            return node
        }

        /// Creates an HTML.RootNode from a libxml2 element root node.
        ///
        /// - Parameters:
        ///     - rawNode: the libxml2 xmlNode.
        ///
        /// - Returns: the HTML.RootNode
        ///
        private func createRootNode(rawNode: xmlNode) -> RootNode {
            var children = [Node]()

            if rawNode.children != nil {
                let nodesConverter = NodesConverter()
                children.appendContentsOf(nodesConverter.convert(rawNode.children))
            }

            let node = RootNode(children: children)

            // TODO: This can be optimized to be set during instantiation of the child nodes.
            //
            for child in children {
                child.parent = node
            }
            
            return node
        }

        /// Creates an HTML.TextNode from a libxml2 element node.
        ///
        /// - Parameters:
        ///     - rawNode: the libxml2 xmlNode.
        ///
        /// - Returns: the HTML.TextNode
        ///
        private func createTextNode(rawNode: xmlNode) -> TextNode {
            let text = String(CString: UnsafePointer<Int8>(rawNode.content), encoding: NSUTF8StringEncoding)!
            let node = TextNode(text: text)

            return node
        }

        /// Creates an HTML.CommentNode from a libxml2 element node.
        ///
        /// - Parameters:
        ///     - rawNode: the libxml2 xmlNode.
        ///
        /// - Returns: the HTML.CommentNode
        ///
        private func createCommentNode(rawNode: xmlNode) -> CommentNode {
            let text = String(CString: UnsafePointer<Int8>(rawNode.content), encoding: NSUTF8StringEncoding)!
            let node = CommentNode(text: text)

            return node
        }

        private func getNodeName(rawNode: xmlNode) -> String {
            return String(CString: UnsafePointer<Int8>(rawNode.name), encoding: NSUTF8StringEncoding)!
        }
    }
}