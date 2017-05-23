import Foundation

extension Libxml2 {
    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node, LeafNode {

        var contents: String

        // MARK: - CustomReflectable
        
        override public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["type": "text", "name": name, "text": contents, "parent": parent.debugDescription], ancestorRepresentation: .suppressed)
            }
        }
        
        // MARK: - Initializers
        
        init(text: String) {
            contents = text

            super.init(name: "text")
        }

        /// Node length.
        ///
        override func length() -> Int {
            return contents.characters.count
        }
                
        // MARK: - LeafNode
        
        override func text() -> String {
            return contents
        }

        // MARK: - Undo support
        
        private func registerUndoForAppend(appendedLength: Int) {
            /*
            SharedEditor.currentEditor.undoManager.registerUndo(withTarget: self) { target in
                let endIndex = target.contents.endIndex
                let range = target.contents.index(endIndex, offsetBy: -appendedLength)..<endIndex
                
                target.contents.removeSubrange(range)
            }
 */
        }
        
        private func registerUndoForDeleteCharacters(inRange subrange: Range<String.Index>) {
            /*
            let index = subrange.lowerBound
            let removedContent = contents.substring(with: subrange).characters
            
            SharedEditor.currentEditor.undoManager.registerUndo(withTarget: self) { target in
                target.contents.insert(contentsOf: removedContent, at: index)
            }
 */
        }
        
        private func registerUndoForPrepend(prependedLength: Int) {
            /*
            SharedEditor.currentEditor.undoManager.registerUndo(withTarget: self) { target in
                let startIndex = target.contents.startIndex
                let range = startIndex ..< target.contents.index(startIndex, offsetBy: prependedLength)
                
                target.contents.removeSubrange(range)
            }
 */
        }
        
        private func registerUndoForReplaceCharacters(in range: Range<String.Index>, withString string: String) {
            /*
            let index = range.lowerBound
            let originalString = contents.substring(with: range)
            
            SharedEditor.currentEditor.undoManager.registerUndo(withTarget: self) { target in
                let newStringRange = index ..< target.contents.index(index, offsetBy: string.characters.count)
                
                target.contents.replaceSubrange(newStringRange, with: originalString)
            }
 */
        }
    }
}
