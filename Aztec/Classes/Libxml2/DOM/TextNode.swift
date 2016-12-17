import Foundation

extension Libxml2 {
    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node, EditableNode, LeafNode {

        fileprivate var contents: String

        // MARK: - CustomReflectable
        
        override public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["type": "text", "name": name, "text": contents, "parent": parent.debugDescription], ancestorRepresentation: .suppressed)
            }
        }
        
        // MARK: - Initializers
        
        init(text: String, registerUndo: @escaping UndoRegistrationClosure) {
            contents = text

            super.init(name: "text", registerUndo: registerUndo)
        }

        /// Node length.
        ///
        override func length() -> Int {
            return contents.characters.count
        }

        // MARK: - EditableNode
        
        func append(_ string: String) {
            registerUndoForAppend(appendedLength: string.characters.count)
            contents.append(string)
        }

        func deleteCharacters(inRange range: NSRange) {

            guard let textRange = contents.rangeFromNSRange(range) else {
                fatalError("The specified range is out of bounds.")
            }

            registerUndoForDeleteCharacters(inRange: textRange)
            contents.removeSubrange(textRange)
        }
        
        func prepend(_ string: String) {
            registerUndoForPrepend(prependedLength: string.characters.count)
            contents = "\(string)\(contents)"
        }

        func replaceCharacters(inRange range: NSRange, withString string: String, inheritStyle: Bool) {

            guard let textRange = contents.rangeFromNSRange(range) else {
                fatalError("The specified range is out of bounds.")
            }

            contents.replaceSubrange(textRange, with: string)
        }

        func split(atLocation location: Int) {
            
            guard location != 0 && location != length() else {
                // Nothing to split, move along...
                
                return
            }
            
            guard location > 0 && location < length() else {
                fatalError("Out of bounds!")
            }
            
            let index = text().characters.index(text().startIndex, offsetBy: location)
            
            guard let parent = parent,
                let nodeIndex = parent.children.index(of: self) else {
                    
                    fatalError("This scenario should not be possible. Review the logic.")
            }
            
            let postRange = index ..< text().endIndex
            
            if postRange.lowerBound != postRange.upperBound {
                let newNode = TextNode(text: text().substring(with: postRange), registerUndo: registerUndo)
                
                contents.removeSubrange(postRange)
                parent.insert(newNode, at: nodeIndex + 1)
            }
        }
        
        func split(forRange range: NSRange) {

            guard let swiftRange = contents.rangeFromNSRange(range) else {
                fatalError("This scenario should not be possible. Review the logic.")
            }

            guard let parent = parent,
                let nodeIndex = parent.children.index(of: self) else {

                fatalError("This scenario should not be possible. Review the logic.")
            }

            let preRange = contents.startIndex ..< swiftRange.lowerBound
            let postRange = swiftRange.upperBound ..< contents.endIndex

            if !postRange.isEmpty {
                let newNode = TextNode(text: contents.substring(with: postRange), registerUndo: registerUndo)

                contents.removeSubrange(postRange)
                parent.insert(newNode, at: nodeIndex + 1)
            }
            
            if !preRange.isEmpty {
                let newNode = TextNode(text: contents.substring(with: preRange), registerUndo: registerUndo)

                contents.removeSubrange(preRange)
                parent.insert(newNode, at: nodeIndex)
            }
        }


        /// Wraps the specified range inside a node with the specified name.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func wrap(range targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor) {

            guard !NSEqualRanges(targetRange, NSRange(location: 0, length: length())) else {
                wrap(inElement: elementDescriptor)
                return
            }

            split(forRange: targetRange)
            wrap(inElement: elementDescriptor)
        }
        
        // MARK: - LeadNode
        
        override func text() -> String {
            return contents
        }
        
        // MARK: - Undo support
        
        private func registerUndoForAppend(appendedLength: Int) {
            registerUndo { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                let endIndex = strongSelf.contents.endIndex
                let range = strongSelf.contents.index(endIndex, offsetBy: -appendedLength)..<endIndex
                
                strongSelf.contents.removeSubrange(range)
            }
        }
        
        private func registerUndoForDeleteCharacters(inRange range: Range<String.CharacterView.Index>) {
            let originalText = contents.substring(with: range)
            let index = range.lowerBound
            
            registerUndo { [weak self] in
                self?.contents.insert(contentsOf: originalText.characters, at: index)
            }
        }
        
        private func registerUndoForPrepend(prependedLength: Int) {
            registerUndo { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                let startIndex = strongSelf.contents.startIndex
                let range = startIndex..<strongSelf.contents.index(startIndex, offsetBy: prependedLength)
                
                strongSelf.contents.removeSubrange(range)
            }
        }
        
        private func registerUndoForReplaceCharacters(at index: String.CharacterView.Index, originalString: String, newStringLength: String.IndexDistance) {
            
            registerUndo { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                let newStringRange = index..<strongSelf.contents.index(index, offsetBy: newStringLength)
                
                strongSelf.contents.replaceSubrange(newStringRange, with: originalString)
            }
        }
    }
}
