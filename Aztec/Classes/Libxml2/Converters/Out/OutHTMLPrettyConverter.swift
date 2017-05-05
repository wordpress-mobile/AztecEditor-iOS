import Foundation
import libxml2

extension Libxml2.Out {
    class HTMLPrettyConverter: Converter {

        typealias Attribute = Libxml2.Attribute
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


// MARK: - Private
//
private extension Libxml2.Out.HTMLPrettyConverter {

    ///
    ///
    func export(node: Node) -> String {
        switch node {
        case let commentNode as CommentNode:
            return "\n" + createCommentNode(commentNode)
        case let elementNode as ElementNode:
            return "\n" + createElementNode(elementNode)
        case let textNode as TextNode:
            return createTextNode(textNode)
        default:
            fatalError("We're missing support for a node type.  This should not happen.")
        }
    }

    ///
    ///
    func createElementNode(_ rawNode: ElementNode) -> String {
        guard rawNode.children.isEmpty == false else {
            return "<" + rawNode.name + " />"
        }

        var string = "<" + rawNode.name + ">"
//        let attributeConverter = AttributeConverter(forNode: node)
//
//        for rawAttribute in rawNode.attributes {
//            let _ = attributeConverter.convert(rawAttribute)
//        }

        for child in rawNode.children {
            string += export(node: child)
        }

        string += "</" + rawNode.name + ">"

        return string
    }

    ///
    ///
    func createTextNode(_ rawNode: TextNode) -> String {
        return rawNode.text()
    }

    ///
    ///
    func createCommentNode(_ rawNode: CommentNode) -> String {
        return "<!--" + rawNode.comment + "-->"
    }
}
