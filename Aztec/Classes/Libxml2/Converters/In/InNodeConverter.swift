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
        typealias UndoRegistrationClosure = Node.UndoRegistrationClosure
        
        let registerUndo: UndoRegistrationClosure
        
        required init(registerUndo: @escaping UndoRegistrationClosure) {
            self.registerUndo = registerUndo
        }
        
        /// Converts a single node (from libxml2) into an HTML.Node.
        ///
        /// - Parameters:
        ///     - attributes: the libxml2 attribute to convert.
        ///
        /// - Returns: an HTML.Node.
        ///
        func convert(_ rawNode: xmlNode) -> Node {
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

        fileprivate func createAttributes(fromNode rawNode: xmlNode) -> [Attribute] {
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
        fileprivate func createElementNode(_ rawNode: xmlNode) -> ElementNode {

            let nodeName = getNodeName(rawNode)

            switch nodeName.lowercased() {
            case RootNode.name:
                return createRootNode(rawNode)
            default:
                break
            }

            var children = [Node]()

            if rawNode.children != nil {
                let nodesConverter = NodesConverter(registerUndo: registerUndo)
                children.append(contentsOf: nodesConverter.convert(rawNode.children))
            }

            let attributes = createAttributes(fromNode: rawNode)
            let node = ElementNode(name: nodeName, attributes: attributes, children: children, registerUndo: registerUndo)

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
        fileprivate func createRootNode(_ rawNode: xmlNode) -> RootNode {
            var children = [Node]()

            if rawNode.children != nil {
                let nodesConverter = NodesConverter(registerUndo: registerUndo)
                children.append(contentsOf: nodesConverter.convert(rawNode.children))
            }

            let node = RootNode(children: children, registerUndo: registerUndo)

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
        fileprivate func createTextNode(_ rawNode: xmlNode) -> TextNode {
            let text = String(cString: rawNode.content)
            let cleanText = text.replacingOccurrences(of: "\n", with: "")
            let node = TextNode(text: cleanText, registerUndo: registerUndo)

            return node
        }

        /// Creates an HTML.CommentNode from a libxml2 element node.
        ///
        /// - Parameters:
        ///     - rawNode: the libxml2 xmlNode.
        ///
        /// - Returns: the HTML.CommentNode
        ///
        fileprivate func createCommentNode(_ rawNode: xmlNode) -> CommentNode {
            let text = String(cString: rawNode.content)
            let node = CommentNode(text: text, registerUndo: registerUndo)

            return node
        }

        fileprivate func getNodeName(_ rawNode: xmlNode) -> String {
            return String(cString: rawNode.name)
        }
    }
}
