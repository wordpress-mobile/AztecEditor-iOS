import Aztec
import Foundation

/// Processes an HTML Tree to replace Gutenberg comment blocks with gutenblock elements.
///
public class GutenbergInputHTMLTreeProcessor: HTMLTreeProcessor {
    
    typealias OpenerMatch = (offset: Int, opener: CommentNode)
    typealias CloserMatch = (offset: Int, closer: CommentNode)
    
    // MARK: - Initializers
    
    private static let classInitializer: () = {
        Element.blockLevelElements.insert(.gutenblock)

        Element.mergeableBlockLevelElements.insert(.gutenblock)

        Element.mergeableBlocklevelElementsSingleChildren.insert(.gutenblock)
        
        // Self-closing blocks are packed into attachments.
        Element.blockLevelElements.insert(.gutenpack)
    }()
    
    public init() {
        // This is a hack to simulate a class initializer.  The closure will be executed once.
        GutenbergInputHTMLTreeProcessor.classInitializer
    }
    
    typealias Replacement = (range: Range<Int>, nodes: [Node])
    
    public func process(_ rootNode: RootNode) {
        process(rootNode as ElementNode)
    }
    
    public func process(_ elementNode: ElementNode) {
        elementNode.children = process(elementNode.children)
    }
    
    private func process(_ nodes: [Node]) -> [Node] {
        var result = [Node]()
        var openerSlice = nodes[0 ..< nodes.count]
        
        while let (relativeOpenerOffset, opener) = self.nextOpener(in: openerSlice) {
            let openerOffset = openerSlice.startIndex + relativeOpenerOffset
            
            // Any nodes before the first opener found are immediately added to the results.
            result += nodes[openerSlice.startIndex ..< openerOffset]
            
            let nextOffset = openerOffset + 1
            let closerSlice = nodes[nextOffset ..< nodes.count]
            
            guard let (relativeCloserOffset, closer) = nextCloser(in: closerSlice, forOpener: opener) else {
                // If a closer is not found, we just add teh opener as a regular comment block
                // and continue from the following offset (opener offset + 1).
                result.append(opener)
                openerSlice = closerSlice
                
                continue
            }
            
            // If a closer is found, we create a Gutenblock and wrap all nodes between the opener and the closer.
            let closerOffset = closerSlice.startIndex + relativeCloserOffset
            let children = nodes[closerSlice.startIndex ..< closerOffset]
            let gutenblock = self.gutenblock(wrapping: children, opener: opener, closer: closer)
            
            result.append(gutenblock)
            openerSlice = nodes[closerOffset + 1 ..< nodes.count]
        }
        
        if openerSlice.count > 0 {
            result += [Node](openerSlice)
        }
        
        for node in result {
            if let elementNode = node as? ElementNode {
                process(elementNode)
            }
        }
        
        return result
    }
}

// MARK: - Gutenblock pairing logic

private extension GutenbergInputHTMLTreeProcessor {
    private func gutenblock(wrapping nodes: ArraySlice<Node>, opener: CommentNode, closer: CommentNode) -> ElementNode {
        let attributes = openerAttributes(for: opener) + closerAttributes(for: closer)
        let children = [Node](nodes)
        let gutenblock = ElementNode(type: .gutenblock, attributes: attributes, children: children)
        
        return gutenblock
    }
    
    private func nextOpener(in nodes: ArraySlice<Node>) -> OpenerMatch? {
        for (index, node) in nodes.enumerated() {
            guard let commentNode = node as? CommentNode,
                commentNode.isGutenbergBlockOpener() else {
                    continue
            }
            
            return OpenerMatch(offset: index, opener: commentNode)
        }
        
        return nil
    }

    private func nextCloser(in nodes: ArraySlice<Node>, forOpener opener: CommentNode) -> CloserMatch? {
        for (index, node) in nodes.enumerated() {
            guard let commentNode = node as? CommentNode,
                commentNode.isGutenbergBlockCloser(forOpener: opener) else {
                    continue
            }
            
            return CloserMatch(offset: index, closer: commentNode)
        }
        
        return nil
    }
}

// MARK: - Gutenblock attributes

private extension GutenbergInputHTMLTreeProcessor {
    func closerAttributes(for commentNode: CommentNode) -> [Attribute] {
        let attributeName = GutenbergAttributeNames.blockCloser
        let openerBase64String = encode(commentNode)
        
        return [Attribute(name: attributeName, value: .string(openerBase64String))]
    }
    
    func openerAttributes(for commentNode: CommentNode) -> [Attribute] {
        let attributeName = GutenbergAttributeNames.blockOpener
        let openerBase64String = encode(commentNode)
        
        return [Attribute(name: attributeName, value: .string(openerBase64String))]
    }
    
    func selfClosingAttributes(for commentNode: CommentNode) -> [Attribute] {
        let attributeName = GutenbergAttributeNames.selfCloser
        let openerBase64String = encode(commentNode)
        
        return [Attribute(name: attributeName, value: .string(openerBase64String))]
    }
}

// MARK: - Gutenblock Encoding Logic

private extension GutenbergInputHTMLTreeProcessor {
    
    func encode(_ gutenblock: CommentNode) -> String {
        return encode(gutenblock.comment)
    }
    
    private func encode(_ string: String) -> String {
        let data = string.data(using: .utf16)!
        let base64String = data.base64EncodedString()
        
        return base64String
    }
}
