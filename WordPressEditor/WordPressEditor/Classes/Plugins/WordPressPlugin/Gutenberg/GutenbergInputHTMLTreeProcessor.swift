import Aztec
import Foundation

/// Processes an HTML Tree to replace Gutenberg comment blocks with gutenblock elements.
///
public class GutenbergInputHTMLTreeProcessor: HTMLTreeProcessor {
    
    typealias GutenbergDelimiterMatch = (offset: Int, match: CommentNode)
    
    // MARK: - Encoding
    
    let encoder = GutenbergAttributeEncoder()
    
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

        while let (relativeOpenerOffset, match) = self.nextOpenerOrSelfClosing(in: openerSlice) {
            let openerOffset = openerSlice.startIndex + relativeOpenerOffset
            
            // Any nodes before the first match found are immediately added to the results.
            result += nodes[openerSlice.startIndex ..< openerOffset]
            
            if match.isGutenbergBlockOpener() {
                let opener = match

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
            } else if match.isGutenbergSelfClosingBlock() {
                let attributes = [encoder.selfClosingAttribute(for: match)]
                let gutenblock = ElementNode(type: .gutenpack, attributes: attributes, children: [])
                
                result.append(gutenblock)
                let nextOffset = openerOffset + 1
                openerSlice = nodes[nextOffset ..< nodes.count]
            }
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
        let attributes = [encoder.openerAttribute(for: opener), encoder.closerAttribute(for: closer)]
        let children = [Node](nodes)
        let gutenblock = ElementNode(type: .gutenblock, attributes: attributes, children: children)
        
        return gutenblock
    }
    
    private func nextCloser(in nodes: ArraySlice<Node>, forOpener opener: CommentNode) -> GutenbergDelimiterMatch? {
        for (index, node) in nodes.enumerated() {
            guard let commentNode = node as? CommentNode,
                commentNode.isGutenbergBlockCloser(forOpener: opener) else {
                    continue
            }
            
            return GutenbergDelimiterMatch(offset: index, match: commentNode)
        }
        
        return nil
    }
    
    private func nextOpenerOrSelfClosing(in nodes: ArraySlice<Node>) -> GutenbergDelimiterMatch? {
        for (index, node) in nodes.enumerated() {
            guard let commentNode = node as? CommentNode,
                commentNode.isGutenbergBlockOpener() || commentNode.isGutenbergSelfClosingBlock() else {
                    continue
            }
            
            return GutenbergDelimiterMatch(offset: index, match: commentNode)
        }
        
        return nil
    }
}
