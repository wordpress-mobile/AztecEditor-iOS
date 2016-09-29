import Foundation

extension Libxml2 {
    /// Text nodes.  Cannot have child nodes (for now, not sure if we will need them).
    ///
    class TextNode: Node, EditableNode {

        var text: String

        init(text: String) {
            self.text = text

            super.init(name: "text")
        }

        override func customMirror() -> Mirror {
            return Mirror(self, children: ["type": "text", "name": name, "text": text, "parent": parent.debugDescription], ancestorRepresentation: .Suppressed)
        }

        /// Node length.
        ///
        override func length() -> Int {
            return text.characters.count
        }

        // MARK: - EditableNode
        
        func append(string: String) {
            text.appendContentsOf(string)
        }

        func deleteCharacters(inRange range: NSRange) {

            guard let textRange = text.rangeFromNSRange(range) else {
                fatalError("The specified range is out of bounds.")
            }

            text.removeRange(textRange)
        }
        
        func prepend(string: String) {
            text = "\(string)\(text)"
        }

        func replaceCharacters(inRange range: NSRange, withString string: String) {

            guard let textRange = text.rangeFromNSRange(range) else {
                fatalError("The specified range is out of bounds.")
            }

            text.replaceRange(textRange, with: string)
        }

        func split(atLocation location: Int) {
            
            let index = text.startIndex.advancedBy(location)
            
            guard let parent = parent,
                let nodeIndex = parent.children.indexOf(self) else {
                    
                    fatalError("This scenario should not be possible. Review the logic.")
            }
            
            let preRange = text.startIndex ..< index
            let postRange = index ..< text.endIndex
            
            if preRange.count > 0 && postRange.count > 0 {
                let newNode = TextNode(text: text.substringWithRange(postRange))
                
                text.removeRange(postRange)
                parent.insert(newNode, at: nodeIndex + 1)
            }
        }
        
        func split(forRange range: NSRange) {

            guard let swiftRange = text.rangeFromNSRange(range) else {
                fatalError("This scenario should not be possible. Review the logic.")
            }

            guard let parent = parent,
                let nodeIndex = parent.children.indexOf(self) else {

                fatalError("This scenario should not be possible. Review the logic.")
            }

            let preRange = text.startIndex ..< swiftRange.startIndex
            let postRange = swiftRange.endIndex ..< text.endIndex

            if postRange.count > 0 {
                let newNode = TextNode(text: text.substringWithRange(postRange))

                text.removeRange(postRange)
                parent.insert(newNode, at: nodeIndex + 1)
            }

            if preRange.count > 0 {
                let newNode = TextNode(text: text.substringWithRange(preRange))

                text.removeRange(preRange)
                parent.insert(newNode, at: nodeIndex)
            }
        }


        /// Wraps the specified range inside a node with the specified name.
        ///
        /// - Parameters:
        ///     - targetRange: the range that must be wrapped.
        ///     - nodeName: the name of the node to wrap the range in.
        ///     - attributes: the attributes the wrapping node will have when created.
        ///
        func wrap(range targetRange: NSRange, inNodeNamed nodeName: String, withAttributes attributes: [Attribute]) {

            guard !NSEqualRanges(targetRange, NSRange(location: 0, length: length())) else {
                wrap(inNodeNamed: nodeName, withAttributes: attributes)
                return
            }

            split(forRange: targetRange)
            wrap(inNodeNamed: nodeName, withAttributes: attributes)
        }
    }
}
