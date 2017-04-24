import Foundation

extension Libxml2 {
    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node, LeafNode {

        fileprivate var contents: String

        // MARK: - CustomReflectable
        
        override public var customMirror: Mirror {
            get {
                return Mirror(self, children: ["type": "text", "name": name, "text": contents, "parent": parent.debugDescription], ancestorRepresentation: .suppressed)
            }
        }
        
        // MARK: - Initializers
        
        init(text: String, editContext: EditContext? = nil) {
            contents = text

            super.init(name: "text", editContext: editContext)
        }

        /// Node length.
        ///
        override func length() -> Int {
            return contents.characters.count
        }
        
        // MARK: - Editing: Atomic Operations
        
        /// Appends the specified string.  The input data is assumed to be sanitized, which means
        /// this method does not perform verifications or cleanups on it.
        ///
        /// - Parameters:
        ///     - string: the string to append to the node.
        ///
        private func append(sanitizedString string: String) {
            registerUndoForAppend(appendedLength: string.characters.count)
            contents.append(string)
        }
        
        /// Appends the specified components separated by the specified descriptor.
        ///
        /// - Parameters:
        ///     - components: an array of strings that will be appended.  These will be separated
        ///         by the specified separator.
        ///     - separatorDescriptor: the node to use to separate the specified components.
        ///
        private func append(components: [String], separatedBy separatorDescriptor: ElementNodeDescriptor) {
            guard let parent = parent else {
                assertionFailure("This method cannot process newlines if the node's parent isn't set.")
                return
            }
            
            var insertionIndex = parent.indexOf(childNode: self)
            
            for (componentIndex, component) in components.enumerated() {
                if componentIndex == 0 {
                    append(sanitizedString: component)
                    
                    insertionIndex = insertionIndex + 1
                } else {
                    let separator = ElementNode(descriptor: separatorDescriptor)
                    
                    parent.insert(separator, at: insertionIndex)
                    insertionIndex = insertionIndex + 1
                    
                    if !component.isEmpty {
                        let textNode = TextNode(text: component, editContext: editContext)
                        
                        parent.insert(textNode, at: insertionIndex)
                        insertionIndex = insertionIndex + 1
                    }
                }
            }
        }
        
        /// Prepends the specified string.  The input data is assumed to be sanitized, which means
        /// this method does not perform verifications or cleanups on it.
        ///
        /// - Parameters:
        ///     - string: the string to prepend to the node.
        ///
        private func prepend(sanitizedString string: String) {
            registerUndoForPrepend(prependedLength: string.characters.count)
            contents = "\(string)\(contents)"
        }
        
        /// Prepends the specified components separated by the specified descriptor.
        ///
        /// - Parameters:
        ///     - components: an array of strings that will be prepended.  These will be separated
        ///         by the specified separator.
        ///     - separatorDescriptor: the node to use to separate the specified components.
        ///
        private func prepend(components: [String], separatedBy separatorDescriptor: ElementNodeDescriptor) {
            guard let parent = parent else {
                assertionFailure("This method cannot process newlines if the node's parent isn't set.")
                return
            }
            
            var insertionIndex = parent.indexOf(childNode: self)
            
            for (componentIndex, component) in components.enumerated() {
                if componentIndex == components.count - 1 {
                    prepend(sanitizedString: component)
                } else {
                    let textNode = TextNode(text: component, editContext: editContext)
                    let separator = ElementNode(descriptor: separatorDescriptor)
                    
                    parent.insert(textNode, at: insertionIndex)
                    parent.insert(separator, at: insertionIndex + 1)
                    
                    insertionIndex = insertionIndex + 2
                }
            }
        }
        
        /// Replaces the specified range with a new string.  The input string is assumed to be
        /// sanitized, which means this method does not perform verifications or cleanups on it.
        ///
        /// - Parameters:
        ///     - nsRange: the range to replace.
        ///     - string: the string that will replace the specified range.
        ///
        private func replaceCharacters(inRange nsRange: NSRange, withSanitizedString string: String) {
            
            let range = contents.range(from: nsRange)

            registerUndoForReplaceCharacters(in: range, withString: string)
            contents.replaceSubrange(range, with: string)
        }
        
        /// Replaces the specified range with an array of string components separated by the
        /// specified descriptor.
        ///
        /// This could be use, for example, to separate components with line breaks.
        ///
        /// - Parameters:
        ///     - range: the range to replace.
        ///     - components: an array of strings that will be inserted replacing the specified
        ///         range.  These will be separated by the specified separator.
        ///     - separatorDescriptor: the node to use to separate the specified components.
        ///
        private func replaceCharacters(inRange range: NSRange,
                                       withComponents components: [String],
                                       separatedBy separatorDescriptor: ElementNodeDescriptor) {
            
            guard components.count > 0 else {
                assertionFailure("Do not call this method with an empty list of components.")
                return
            }
            
            guard components.count > 1 else {
                replaceCharacters(inRange: range, withSanitizedString: components[0])
                return
            }
            
            deleteCharacters(inRange: range)
            
            if range.location == 0 {
                prepend(components: components, separatedBy: separatorDescriptor)
            } else if range.location == length() {
                append(components: components, separatedBy: separatorDescriptor)
            } else {
                split(atLocation: range.location)
                
                guard let parent = parent else {
                    assertionFailure("This method cannot process newlines if the node's parent isn't set.")
                    return
                }
                
                let leftNodeIndex = parent.indexOf(childNode: self)
                let rightNodeIndex = leftNodeIndex + 1
                
                assert(parent.children.count > rightNodeIndex)
                
                guard let rightNode = parent.children[rightNodeIndex] as? TextNode else {
                    assertionFailure("The right node should also be a TextNode.  Review the logic.")
                    return
                }
                
                var insertionIndex = parent.indexOf(childNode: self) + 1
                
                for (index, component) in components.enumerated() {
                    if index == 0 {
                        append(sanitizedString: component)
                        
                        let separator = ElementNode(descriptor: separatorDescriptor)
                        
                        parent.insert(separator, at: insertionIndex)
                        insertionIndex = insertionIndex + 1
                    } else if index == components.count - 1 {
                        rightNode.prepend(sanitizedString: component)
                    } else {
                        let textNode = TextNode(text: component, editContext: editContext)
                        let separator = ElementNode(descriptor: separatorDescriptor)
                        
                        parent.insert(textNode, at: insertionIndex)
                        parent.insert(separator, at: insertionIndex + 1)
                        
                        insertionIndex = insertionIndex + 2
                    }
                }
            }
        }

        // MARK: - EditableNode

        func append(_ string: String) {
            guard shouldSanitizeText() else {
                append(sanitizedString: string)
                return
            }
            let components = string.components(separatedBy: String(.newline))
            
            if components.count == 1 {
                append(sanitizedString: string)
            } else {
                append(components: components, separatedBy: ElementNodeDescriptor(elementType: .br))
            }
        }

        override func deleteCharacters(inRange nsRange: NSRange) {

            let range = contents.range(from: nsRange)
            
            deleteCharacters(inRange: range)
        }
        
        func deleteCharacters(inRange range: Range<String.Index>) {
            
            registerUndoForDeleteCharacters(inRange: range)
            contents.removeSubrange(range)
        }
        
        func prepend(_ string: String) {
            let components = string.components(separatedBy: String(.newline))
            
            if components.count == 1 {
                prepend(sanitizedString: string)
            } else {
                prepend(components: components, separatedBy: ElementNodeDescriptor(elementType: .br))
            }
        }

        func hasAncestor(ofType type: StandardElementType) -> Bool {
            var parentNode = self.parent
            while parentNode != nil {
                if let node = parentNode, node.name == type.rawValue {
                    return false
                }
                parentNode = parentNode?.parent
            }
            return true
        }

        /// This method check that in the current context it makes sense to clean up newlines and double spaces from text.
        /// For example if you are inside a pre element you shoulnd't clean up the nodes.
        ///
        /// - Returns: true if sanitization should happen, false otherwise
        ///
        func shouldSanitizeText() -> Bool {
            return hasAncestor(ofType: .pre)
        }

        override func replaceCharacters(inRange range: NSRange, withString string: String) {
            guard shouldSanitizeText() else {
                replaceCharacters(inRange: range, withSanitizedString: string)
                return
            }
            let components = string.components(separatedBy: String(.newline))
            
            if components.count == 1 {
                replaceCharacters(inRange: range, withSanitizedString: string)
            } else {
                replaceCharacters(inRange: range, withComponents: components, separatedBy: ElementNodeDescriptor(elementType: .br))
            }
        }

        override func split(atLocation location: Int) {
            
            guard location != 0 && location != length() else {
                // Nothing to split, move along...
                
                return
            }
            
            guard location > 0 && location < length() else {
                fatalError("Out of bounds!")
            }

            
            guard
                let index = text().indexFromLocation(location),
                let parent = parent,
                let nodeIndex = parent.children.index(of: self) else {
                    
                    fatalError("This scenario should not be possible. Review the logic.")
            }
            
            let postRange = index ..< text().endIndex
            
            if postRange.lowerBound != postRange.upperBound {
                let newNode = TextNode(text: text().substring(with: postRange), editContext: editContext)
                
                deleteCharacters(inRange: postRange)
                parent.insert(newNode, at: nodeIndex + 1)
            }
        }
        
        override func split(forRange range: NSRange) {

            let swiftRange = contents.range(from: range)

            guard let parent = parent,
                let nodeIndex = parent.children.index(of: self) else {

                fatalError("This scenario should not be possible. Review the logic.")
            }

            let preRange = contents.startIndex ..< swiftRange.lowerBound
            let postRange = swiftRange.upperBound ..< contents.endIndex

            if !postRange.isEmpty {
                let newNode = TextNode(text: contents.substring(with: postRange), editContext: editContext)

                deleteCharacters(inRange: postRange)
                parent.insert(newNode, at: nodeIndex + 1, tryToMergeWithSiblings: false)
            }
            
            if !preRange.isEmpty {
                let newNode = TextNode(text: contents.substring(with: preRange), editContext: editContext)

                deleteCharacters(inRange: preRange)
                parent.insert(newNode, at: nodeIndex, tryToMergeWithSiblings: false)
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
                wrap(in: elementDescriptor)
                return
            }

            split(forRange: targetRange)
            wrap(in: elementDescriptor)
        }
        
        // MARK: - LeafNode
        
        override func text() -> String {
            return contents
        }

        // MARK: - Undo support
        
        private func registerUndoForAppend(appendedLength: Int) {
            
            guard let editContext = editContext else {
                return
            }
            
            editContext.undoManager.registerUndo(withTarget: self) { target in
                let endIndex = target.contents.endIndex
                let range = target.contents.index(endIndex, offsetBy: -appendedLength)..<endIndex
                
                target.contents.removeSubrange(range)
            }
        }
        
        private func registerUndoForDeleteCharacters(inRange subrange: Range<String.Index>) {
            
            guard let editContext = editContext else {
                return
            }
            
            let index = subrange.lowerBound
            let removedContent = contents.substring(with: subrange).characters
            
            editContext.undoManager.registerUndo(withTarget: self) { target in
                target.contents.insert(contentsOf: removedContent, at: index)
            }
        }
        
        private func registerUndoForPrepend(prependedLength: Int) {
            
            guard let editContext = editContext else {
                return
            }
            
            editContext.undoManager.registerUndo(withTarget: self) { target in
                let startIndex = target.contents.startIndex
                let range = startIndex ..< target.contents.index(startIndex, offsetBy: prependedLength)
                
                target.contents.removeSubrange(range)
            }
        }
        
        private func registerUndoForReplaceCharacters(in range: Range<String.Index>, withString string: String) {
            
            guard let editContext = editContext else {
                return
            }
            
            let index = range.lowerBound
            let originalString = contents.substring(with: range)
            
            editContext.undoManager.registerUndo(withTarget: self) { target in
                let newStringRange = index ..< target.contents.index(index, offsetBy: string.characters.count)
                
                target.contents.replaceSubrange(newStringRange, with: originalString)
            }
        }
    }
}
