import Aztec
import Foundation

/// Processes an HTML Tree to replace Gutenberg comment blocks with gutenblock elements.
///
public class GutenbergInputHTMLTreeProcessor: HTMLTreeProcessor {
    
    // MARK: - Initializers
    
    private static let classInitializer: () = {
        Element.blockLevelElements.append(.gutenblock)
        
        // Self-closing blocks are packed into attachments.
        Element.blockLevelElements.append(.gutenpack)
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
        process(elementNode: rootNode)
    }
    
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
    }

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
