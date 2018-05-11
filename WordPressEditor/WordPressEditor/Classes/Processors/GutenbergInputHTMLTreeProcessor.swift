import Aztec
import Foundation

/// Processes an HTML Tree to replace Gutenberg comment blocks with gutenblock elements.
///
public class GutenbergInputHTMLTreeProcessor: HTMLTreeProcessor {
    
    private static let classInitializer: () = {
        Element.blockLevelElements.append(.gutenblock)
    }()
    
    public init() {
        // This is a hack to simulate a class initializer.  The closure will be executed once.
        GutenbergInputHTMLTreeProcessor.classInitializer
    }
    
    private enum State {
        case noBlock
        case block(opener: CommentNode, gutenblock: ElementNode)
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
                state = process(node)
                
                if case let .block(_, gutenblock) = state {
                    // As soon as the .block state beings, we insert a gutenblock element.
                    // The children of this gutenblock will be inserted in the .block case handler
                    // until the block's end is reached.
                    return gutenblock
                } else {
                    return node
                }
            case .block(let opener, let gutenblock):
                // This specific case ensures we support multiple levels of gutenblocks.
                if let elementNode = node as? ElementNode {
                    process(elementNode: elementNode)
                }
                
                // If the node is the gutenblock closer, the state will change to .noBlock.
                // If it's any other node, it will be added to the gutenblock's children.
                state = process(node, opener: opener, gutenblock: gutenblock)
                
                return nil
            }
        }
    }
    
    private func process(_ node: Node) -> State {
        guard let commentNode = node as? CommentNode,
            isGutenbergOpener(commentNode) else {
            return .noBlock
        }
        
        let openerAttribute = self.openerAttribute(for: commentNode)
        let element = ElementNode(type: .gutenblock, attributes: [openerAttribute], children: [])
        
        return .block(opener: commentNode, gutenblock: element)
    }

    private func process(_ node: Node, opener: CommentNode, gutenblock: ElementNode) -> State {
        guard let commentNode = node as? CommentNode,
            isGutenbergCloser(commentNode, forOpener: opener) else {
                
            gutenblock.children.append(node)
            return .block(opener: opener, gutenblock: gutenblock)
        }
        
        let closerAttribute = self.closerAttribute(for: commentNode)
        
        gutenblock.attributes.append(closerAttribute)
        
        return .noBlock
    }
}

// MARK: - Gutenblock attributes

private extension GutenbergInputHTMLTreeProcessor {
    func closerAttribute(for commentNode: CommentNode) -> Attribute {
        let openerBase64String = encode(commentNode)
        return Attribute(name: "closer", value: .string(openerBase64String))
    }
    
    func openerAttribute(for commentNode: CommentNode) -> Attribute {
        let openerBase64String = encode(commentNode)
        return Attribute(name: "opener", value: .string(openerBase64String))
    }
}

// MARK: - Gutenblock identification logic

private extension GutenbergInputHTMLTreeProcessor {
    
    static let openerPrefix = "wp:"
    static let closerPrefix = "/wp:"
    
    func isGutenbergCloser(_ commentNode: CommentNode, forOpener opener: CommentNode) -> Bool {
        return isGutenbergCloser(commentNode) && canAssociate(opener: opener, withCloser: commentNode)
    }
    
    func isGutenbergOpener(_ commentNode: CommentNode) -> Bool {
        let prefix = GutenbergInputHTMLTreeProcessor.openerPrefix
        
        return commentNode.comment.trimmingCharacters(in: .whitespaces).prefix(prefix.count) == prefix
    }
    
    // MARK: - Internal logic
    
    private func canAssociate(opener: CommentNode, withCloser closer: CommentNode) -> Bool {
        return openerName(for: opener) == closerName(for: closer)
    }
    
    private func openerName(for commentNode: CommentNode) -> String {
        let openerName = commentNode.comment.trimmingCharacters(in: .whitespaces).prefix { (character) -> Bool in
            // CharacterSet doesn't yet support multi-UnicodeScalar comparisons, so we settle
            // with the ugly solution of only comparing against the first UnicodeScalar in Character.
            // I believe this may just work, even though having to do this is just horrible.
            return !CharacterSet.whitespacesAndNewlines.contains(character.unicodeScalars.first!)
        }
        
        return String(openerName)
    }
    
    private func closerName(for commentNode: CommentNode) -> String {
        return commentNode.comment.trimmingCharacters(in: .whitespaces).prefix { (character) -> Bool in
            // CharacterSet doesn't yet support multi-UnicodeScalar comparisons, so we settle
            // with the ugly solution of only comparing against the first UnicodeScalar in Character.
            // I believe this may just work, even though having to do this is just horrible.
            return !CharacterSet.whitespacesAndNewlines.contains(character.unicodeScalars.first!)
        }.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    
    private func isGutenbergCloser(_ commentNode: CommentNode) -> Bool {
        let prefix = GutenbergInputHTMLTreeProcessor.closerPrefix
        
        return commentNode.comment.trimmingCharacters(in: .whitespaces).prefix(prefix.count) == prefix
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
