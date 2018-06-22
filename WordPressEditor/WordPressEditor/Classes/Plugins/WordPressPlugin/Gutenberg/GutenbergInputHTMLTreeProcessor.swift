import Aztec
import Foundation

/// Processes an HTML Tree to replace Gutenberg comment blocks with gutenblock elements.
///
public class GutenbergInputHTMLTreeProcessor: HTMLTreeProcessor {
    
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
    
    private enum State {
        case noBlock
        case blockInProgress(opener: CommentNode, gutenblock: ElementNode)
    }
    
    typealias Replacement = (range: Range<Int>, nodes: [Node])
    
    public func process(_ rootNode: RootNode) {
        process(rootNode as ElementNode)
    }
    
    public func process(_ elementNode: ElementNode) {
        elementNode.children = process(elementNode.children)
    }
/*
    typealias GutenbergCommentMatch = (index: Int, commentNode: CommentNode)
    typealias GutenbergCommentMatches = (openers: GutenbergCommentMatch, closers: GutenbergCommentMatch)
    typealias GutenbergCommentMatchPair = (openerMatch: GutenbergCommentMatch, closerMatch: GutenbergCommentMatch)
    
    private func pairedGutenbergComments(in nodes: [Node]) -> [GutenbergCommentMatchPair] {
        let gutenbergCommentMatches = findGutenbergComments(in: nodes)
        var currentIndex = 0
        var pairs = [GutenbergCommentMatchPair]()
        
        while currentIndex + 1 < gutenbergCommentMatches.count {
            let possibleOpenerMatch = gutenbergCommentMatches[currentIndex]
            let possibleCloserMatch = gutenbergCommentMatches[currentIndex + 1]
            
            let possibleOpener = possibleOpenerMatch.commentNode
            let possibleCloser = possibleCloserMatch.commentNode
            
            guard possibleOpener.isGutenbergBlockOpener()
                && possibleCloser.isGutenbergBlockCloser(forOpener: possibleOpener) else {
                    currentIndex += 1
                    continue
            }
            
            let newPair = GutenbergCommentMatchPair(openerMatch: possibleOpenerMatch, closerMatch: possibleCloserMatch)
            pairs.append(newPair)
            
            currentIndex += 2
        }
    }
    
    private func findGutenbergComments(in nodes: [Node]) -> [GutenbergCommentMatch] {
        return nodes.enumerated().compactMap { value -> GutenbergCommentMatch? in
            guard let commentNode = value.element as? CommentNode,
                commentNode.isGutenbergBlockOpener() || commentNode.isGutenbergBlockCloser() else {
                    return nil
            }
            
            return GutenbergCommentMatch(index: value.offset, commentNode: commentNode)
        }
    }
*/
    /*
    private func process(elementNode: ElementNode) {
        var state: State = .noBlock
        
        elementNode.children = elementNode.children.compactMap { (node) -> Node? in
            switch state {
            case .noBlock:
                let (newState, nodeToAppend) = process(node)
                
                state = newState
                return nodeToAppend
            case .blockInProgress(let opener, let gutenblock):
                if let elementNode = node as? ElementNode {
                    // This call ensures we support multiple levels of gutenblocks.
                    process(elementNode: elementNode)
                }
                
                // If the node is the gutenblock closer, the state will change to .noBlock.
                // If it's any other node, it will be added to the gutenblock's children.
                state = process(node, opener: opener, gutenblock: gutenblock)
                
                return nil
            }
        }
        
        if case let .blockInProgress(opener, gutenblock) = state {
            
        }
    }*/
    
    typealias OpenerMatch = (offset: Int, opener: CommentNode)
    typealias CloserMatch = (offset: Int, closer: CommentNode)
    
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
    
    private func process(_ nodes: [Node]) -> [Node] {
        var result = [Node]()
        var openerSlice = nodes[0 ..< nodes.count]
        
        while let (relativeOpenerOffset, opener) = self.nextOpener(in: openerSlice) {
            let openerOffset = openerSlice.startIndex + relativeOpenerOffset
            
            result += nodes[openerSlice.startIndex ..< openerOffset]
            
            let nextOffset = openerOffset + 1
            let closerSlice = nodes[nextOffset ..< nodes.count]
            
            guard let (relativeCloserOffset, closer) = nextCloser(in: closerSlice, forOpener: opener) else {
                result.append(opener)
                openerSlice = closerSlice
                
                continue
            }
            
            let closerOffset = closerSlice.startIndex + relativeCloserOffset
            
            let attributes = openerAttributes(for: opener) + closerAttributes(for: closer)
            let children = [Node](nodes[closerSlice.startIndex ..< closerOffset])
            let gutenblock = ElementNode(type: .gutenblock, attributes: attributes, children: children)
            
            result.append(gutenblock)
            
            process(gutenblock)
            
            openerSlice = nodes[closerOffset + 1 ..< nodes.count]
        }
        
        if openerSlice.count > 0 {
            result += [Node](openerSlice)
        }
        
        return result
    }
    
/*
    private func process(_ node: Node) -> (newState: State, nodeToAppend: Node) {
        if let commentNode = node as? CommentNode {
            if commentNode.isGutenbergBlockOpener() {
                let attributes = self.openerAttributes(for: commentNode)
                let element = ElementNode(type: .gutenblock, attributes: attributes, children: [])
                let newState: State = .blockInProgress(opener: commentNode, gutenblock: element)
                
                return (newState, element)
            } else if commentNode.isGutenbergSelfClosingBlock() {
                let attributes = self.selfClosingAttributes(for: commentNode)
                let element = ElementNode(type: .gutenpack, attributes: attributes, children: [])
                
                return (.noBlock, element)
            }
        }
        
        return (.noBlock, node)
    }

    private func process(_ node: Node, opener: CommentNode, gutenblock: ElementNode) -> State {
        guard let commentNode = node as? CommentNode,
            commentNode.isGutenbergBlockCloser(forOpener: opener) else {

            gutenblock.children.append(node)
            return .blockInProgress(opener: opener, gutenblock: gutenblock)
        }
        
        let closerAttributes = self.closerAttributes(for: commentNode)
        
        gutenblock.attributes.append(contentsOf: closerAttributes)
        
        return .noBlock
    }
 */
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
