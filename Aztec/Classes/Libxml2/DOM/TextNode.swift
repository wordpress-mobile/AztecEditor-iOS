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
        
        init(text: String) {
            contents = text

            super.init(name: "text")
        }

        /// Node length.
        ///
        override func length() -> Int {
            return contents.characters.count
        }

        // MARK: - EditableNode
        
        func append(_ string: String, undoManager: NSUndoManager? = nil) {
            contents.append(string)
        }

        func deleteCharacters(inRange range: NSRange, undoManager: NSUndoManager? = nil) {

            guard let textRange = contents.rangeFromNSRange(range) else {
                fatalError("The specified range is out of bounds.")
            }

            contents.removeSubrange(textRange)
        }
        
        func prepend(_ string: String, undoManager: NSUndoManager? = nil) {
            contents = "\(string)\(contents)"
        }

        func replaceCharacters(inRange range: NSRange, withString string: String, inheritStyle: Bool, undoManager: NSUndoManager? = nil) {

            guard let textRange = contents.rangeFromNSRange(range) else {
                fatalError("The specified range is out of bounds.")
            }

            contents.replaceSubrange(textRange, with: string)
        }

        func split(atLocation location: Int, undoManager: NSUndoManager? = nil) {
            
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
                let newNode = TextNode(text: text().substring(with: postRange))
                
                contents.removeSubrange(postRange)
                parent.insert(newNode, at: nodeIndex + 1)
            }
        }
        
        func split(forRange range: NSRange, undoManager: NSUndoManager? = nil) {

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
                let newNode = TextNode(text: contents.substring(with: postRange))

                contents.removeSubrange(postRange)
                parent.insert(newNode, at: nodeIndex + 1, undoManager: undoManager)
            }
            
            if !preRange.isEmpty {
                let newNode = TextNode(text: contents.substring(with: preRange))

                contents.removeSubrange(preRange)
                parent.insert(newNode, at: nodeIndex, undoManager: undoManager)
            }
        }


        /// Wraps the specified range inside a node with the specified name.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - elementDescriptor: the descriptor for the element to wrap the range in.
        ///
        func wrap(range targetRange: NSRange, inElement elementDescriptor: ElementNodeDescriptor, undoManager: NSUndoManager? = nil) {

            guard !NSEqualRanges(targetRange, NSRange(location: 0, length: length())) else {
                wrap(inElement: elementDescriptor, undoManager: undoManager)
                return
            }

            split(forRange: targetRange, undoManager: undoManager)
            wrap(inElement: elementDescriptor, undoManager: undoManager)
        }
        
        // MARK: - LeadNode
        
        override func text() -> String {
            return contents
        }
    }
}
