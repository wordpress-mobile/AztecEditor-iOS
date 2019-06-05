import Foundation


/// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
///
public class TextNode: Node {

    let contents: String

    // MARK: - CustomReflectable
    
    override public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["type": "text", "name": name, "text": contents, "parent": parent.debugDescription], ancestorRepresentation: .suppressed)
        }
    }
    
    // MARK: - Initializers
    
    public init(text: String) {
        contents = text

        super.init(name: "text")
    }

    /// Node length.
    ///
    func length() -> Int {
        return contents.count
    }

    // MARK: - Node

    /// Checks if the specified node requires a closing paragraph separator.
    ///
    override func needsClosingParagraphSeparator() -> Bool {
        guard length() > 0 else {
            return false
        }

        return super.needsClosingParagraphSeparator()
    }
    
    override public func rawText() -> String {
        return contents
    }

    // MARK: - LeafNode
    
    public func text() -> String {
        return contents
    }

    // MARK - Hashable

    override public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(contents)
    }

    // MARK: - Equatable

    override public func isEqual(_ object: Any?) -> Bool {
        guard let textNode = object as? TextNode else {
            return false
        }
        return self.name == textNode.name && self.contents == textNode.contents
    }    
}

// MARK: - Text Sanitization

extension TextNode {
    
    func sanitizedText() -> String {
        guard shouldSanitizeText() else {
            return text()
        }
        
        return sanitize(text())
    }
    
    private func sanitize(_ text: String) -> String {
        guard text != String(.space) else {
            return text
        }
        
        let hasAnEndingSpace = text.hasSuffix(String(.space))
        let hasAStartingSpace = text.hasPrefix(String(.space))
        
        // We cannot use CharacterSet.whitespacesAndNewlines directly, because it includes
        // U+000A, which is non-breaking space.  We need to maintain it.
        //
        let whitespace = CharacterSet.whitespacesAndNewlines
        let whitespaceToKeep = CharacterSet(charactersIn: String(.nonBreakingSpace)+String(.lineSeparator))
        let whitespaceToRemove = whitespace.subtracting(whitespaceToKeep)
        
        let trimmedText = text.trimmingCharacters(in: whitespaceToRemove)
        var singleSpaceText = trimmedText
        let doubleSpace = "  "
        let singleSpace = " "
        
        while singleSpaceText.range(of: doubleSpace) != nil {
            singleSpaceText = singleSpaceText.replacingOccurrences(of: doubleSpace, with: singleSpace)
        }
        
        let noBreaksText = singleSpaceText.replacingOccurrences(of: String(.lineFeed), with: "")
        let endingSpace = !noBreaksText.isEmpty && hasAnEndingSpace ? String(.space) : ""
        let startingSpace = !noBreaksText.isEmpty && hasAStartingSpace ? String(.space) : ""
        return "\(startingSpace)\(noBreaksText)\(endingSpace)"
    }
    
    /// This method check that in the current context it makes sense to clean up newlines and double spaces from text.
    /// For example if you are inside a pre element you shoulnd't clean up the nodes.
    ///
    /// - Returns: true if sanitization should happen, false otherwise
    ///
    private func shouldSanitizeText() -> Bool {
        return !hasAncestor(ofType: .pre)
    }
}
