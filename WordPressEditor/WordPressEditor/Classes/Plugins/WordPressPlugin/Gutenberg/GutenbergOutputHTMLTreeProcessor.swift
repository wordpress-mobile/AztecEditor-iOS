import Aztec
import Foundation

public class GutenbergOutputHTMLTreeProcessor: HTMLTreeProcessor {
    
    private let decoder = GutenbergAttributeDecoder()

    public init() {}
    
    public func process(_ rootNode: RootNode) {
        
        rootNode.children = rootNode.children.flatMap({ (node) -> [Node] in
            guard let element = node as? ElementNode else {
                return [node]
            }
            
            if element.type == .gutenblock {
                return process(gutenblock: element)
            } else if element.type == .gutenpack {
                return process(gutenpack: element)
            } else if element.type == .p {
                // Our output serializer is a bit dumb, and it wraps gutenpack elements into P tags.
                // If we find any, we remove them here.
                return process(paragraph: element)
            } else {
                return [element]
            }
        })
    }
    
    private func process(gutenblock: ElementNode) -> [Node] {
        precondition(gutenblock.type == .gutenblock)
        
        let openingComment = gutenbergOpener(for: gutenblock)
        let containedNodes = gutenblock.children
        let closingComment = gutenbergCloser(for: gutenblock)
        let closingNewline = TextNode(text: "\n")

        return [openingComment] + containedNodes + [closingComment, closingNewline]
    }
    
    private func process(gutenpack: ElementNode) -> [Node] {
        precondition(gutenpack.type == .gutenpack)
        
        let selfContainedBlockComment = gutenbergSelfCloser(for: gutenpack)
        let closingNewline = TextNode(text: "\n")
        
        return [selfContainedBlockComment, closingNewline]
    }
    
    private func process(paragraph: ElementNode) -> [Node] {
        var children = ArraySlice<Node>(paragraph.children)
        var result = [Node]()
        
        while let (index, gutenpack) = nextGutenpack(in: children) {
            let nodesBeforeGutenpack = children.prefix(index)

            if nodesBeforeGutenpack.count > 0 {
                let newParagraph = deepCopy(paragraph, withChildren: Array(nodesBeforeGutenpack))
                
                result.append(newParagraph)
                children = children.dropFirst(nodesBeforeGutenpack.count)
            }
            
            let replacementNodes = process(gutenpack: gutenpack)
            
            result.append(contentsOf: replacementNodes)
            children = children.dropFirst()
        }

        if children.count > 0 {
            paragraph.children = Array(children)
            result.append(paragraph)
        }
        
        return result
    }
    
    private func deepCopy(_ elementNode: ElementNode, withChildren children: [Node]) -> ElementNode {
        let copiedAttributes = elementNode.attributes.map { (attribute) -> Attribute in
            return Attribute(name: attribute.name, value: attribute.value)
        }
        
        return ElementNode(type: elementNode.type, attributes: copiedAttributes, children: children)
    }
    
    private func nextGutenpack(in nodes: ArraySlice<Node>) -> (index: Int, element: ElementNode)? {
        for (index, node) in nodes.enumerated() {
            if let element = node as? ElementNode,
                element.type == .gutenpack {
                
                return (index, element)
            }
        }
        
        return nil
    }
}

// MARK: - Gutenberg Tags

private extension GutenbergOutputHTMLTreeProcessor {
    
    func gutenbergCloser(for element: ElementNode) -> CommentNode {
        guard let closer = gutenblockCloserData(for: element) else {
            fatalError("There's no scenario in which this information missing can make sense.  Review the logic.")
        }
        
        return CommentNode(text: closer)
    }
    
    func gutenbergOpener(for element: ElementNode) -> CommentNode {
        guard let opener = gutenblockOpenerData(for: element) else {
            fatalError("There's no scenario in which this information missing can make sense.  Review the logic.")
        }
    
        return CommentNode(text: opener)
    }
    
    func gutenbergSelfCloser(for element: ElementNode) -> CommentNode {
        guard let selfCloser = gutenblockSelfCloserData(for: element) else {
            fatalError("There's no scenario in which this information missing can make sense.  Review the logic.")
        }
        
        return CommentNode(text: selfCloser)
    }
    
    // MARK: - Gutenberg HTML Attribute Data
    
    private func gutenblockCloserData(for element: ElementNode) -> String? {
        return decoder.attribute(.blockCloser, from: element)
    }
    
    private func gutenblockOpenerData(for element: ElementNode) -> String? {
        return decoder.attribute(.blockOpener, from: element)
    }
    
    private func gutenblockSelfCloserData(for element: ElementNode) -> String? {        
        return decoder.attribute(.selfCloser, from: element)
    }
}
