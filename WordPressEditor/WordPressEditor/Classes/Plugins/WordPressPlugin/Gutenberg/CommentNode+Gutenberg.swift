import Aztec
import Foundation

public extension CommentNode {
    private static let openerPrefix = "wp:"
    private static let closerPrefix = "/wp:"
    private static let selfClosingBlockSuffix = "/"
    
    // MARK: - Opener & Closer Identification
    
    func isGutenbergBlockCloser(forOpener opener: CommentNode) -> Bool {
        return isGutenbergBlockCloser() && opener.canBeClosedBy(self)
    }
    
    func isGutenbergBlockCloser() -> Bool {
        let prefix = CommentNode.closerPrefix
        
        return comment.trimmingCharacters(in: .whitespaces).prefix(prefix.count) == prefix
    }
    
    func isGutenbergBlockOpener() -> Bool {
        let prefix = CommentNode.openerPrefix
        let selfClosingBlockSuffix = CommentNode.selfClosingBlockSuffix
        
        return comment.trimmingCharacters(in: .whitespaces).prefix(prefix.count) == prefix
            && comment.trimmingCharacters(in: .whitespaces).suffix(selfClosingBlockSuffix.count) != selfClosingBlockSuffix
    }
    
    func isGutenbergSelfClosingBlock() -> Bool {
        let prefix = CommentNode.openerPrefix
        let selfClosingBlockSuffix = CommentNode.selfClosingBlockSuffix

        return comment.trimmingCharacters(in: .whitespaces).prefix(prefix.count) == prefix
            && comment.trimmingCharacters(in: .whitespaces).suffix(selfClosingBlockSuffix.count) == selfClosingBlockSuffix
    }
    
    // MARK: - Internal Logic
    
    private func canBeClosedBy(_ closer: CommentNode) -> Bool {
        return openerName(for: self) == closerName(for: closer)
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
}
