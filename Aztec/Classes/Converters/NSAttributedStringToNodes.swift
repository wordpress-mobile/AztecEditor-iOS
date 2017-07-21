import Foundation
import UIKit
import libxml2


// MARK: - NSAttributedStringToNodes
//
class NSAttributedStringToNodes: Converter {

    /// Typealiases
    ///
    typealias Node = Libxml2.Node
    typealias CommentNode = Libxml2.CommentNode
    typealias ElementNode = Libxml2.ElementNode
    typealias RootNode = Libxml2.RootNode
    typealias TextNode = Libxml2.TextNode
    typealias Attribute = Libxml2.Attribute
    typealias StringAttribute = Libxml2.StringAttribute
    typealias StandardElementType = Libxml2.StandardElementType


    /// Converts an Attributed String Instance into it's HTML Tree Representation.
    ///
    /// -   Parameter attrString: Attributed String that should be converted.
    ///
    /// -   Returns: RootNode, representing the DOM Tree.
    ///
    func convert(_ attrString: NSAttributedString) -> RootNode {
        var nodes = [Node]()
        var previous: [Node]?

        attrString.enumerateParagraphRanges(spanning: attrString.rangeOfEntireString) { (paragraphRange, _) in
            let paragraph = attrString.attributedSubstring(from: paragraphRange)
            let children = createNodes(fromParagraph: paragraph)

            if let previous = previous {
                let left = rightmostParagraphStyleElements(from: previous)
                let right = leftmostParagraphStyleElements(from: children)

                guard !merge(left: left, right: right) else {
                    return
                }

                if left.count == 0 && right.count == 0 {
                    nodes += [ ElementNode(type: .br) ]
                }
            }

            nodes += children
            previous = children
        }

        return RootNode(children: nodes)
    }


    /// Converts a *Paragraph* into a collection of Nodes, representing the internal HTML Entities.
    ///
    /// - Parameter paragraph: Paragraph's Attributed String that should be converted.
    ///
    /// - Returns: Array of Node instances.
    ///
    private func createNodes(fromParagraph paragraph: NSAttributedString) -> [Node] {
        guard paragraph.length > 0 else {
            return []
        }

        var branches = [Branch]()

        paragraph.enumerateAttributes(in: paragraph.rangeOfEntireString, options: []) { (attrs, range, _) in

            let substring = paragraph.attributedSubstring(from: range)
            let leafNodes = createLeafNodes(from: substring)
            let styleNodes = createStyleNodes(from: attrs)

            let branch = Branch(nodes: styleNodes, leaves: leafNodes)
            branches.append(branch)
        }

        let paragraphNodes = createParagraphNodes(from: paragraph)
        let processedBranches = process(branches: branches)

        return reduce(nodes: paragraphNodes, leaves: processedBranches)
    }
}


// MARK: - Merge: Helpers
//
private extension NSAttributedStringToNodes {

    /// Defines a Tree Branch: Collection of Nodes, with a set of Leaves
    ///
    typealias Branch = (nodes: [ElementNode], leaves: [Node])


    /// Defines a pair of Nodes that can be merged
    ///
    typealias MergeablePair = (left: ElementNode, right: ElementNode)


    /// Sets Up a collection of Nodes and Leaves as a chain of Parent-Children, and returns the root node.and
    /// If the collection of nodes is empty, will return the leaves parameters 'as is'.
    ///
    func reduce(nodes: [ElementNode], leaves: [Node]) -> [Node] {
        return nodes.reduce(leaves) { (result, node) in
            node.children = result
            return [node]
        }
    }


    /// Finds the Deepest node that can be merged "Right to Left", and returns the Left / Right matching touple, if any.
    ///
    func findMergeableNodes(left: [ElementNode], right: [ElementNode], blocklevelEnforced: Bool = true) -> [MergeablePair]? {
        var currentIndex = 0
        var matching = [MergeablePair]()

        while currentIndex < left.count && currentIndex < right.count {
            let left = left[currentIndex]
            let right = right[currentIndex]

            guard left.canMergeChildren(of: right, blocklevelEnforced: blocklevelEnforced) else {
                break
            }

            let pair = MergeablePair(left: left, right: right)
            matching.append(pair)
            currentIndex += 1
        }

        return matching.isEmpty ? nil : matching
    }
}


// MARK: - Merge: Styles
//
private extension NSAttributedStringToNodes {

    /// Given a collection of branches, this method will iterate branch by branch and will:
    ///
    /// A. Reduce the Nodes: An actuall Parent/Child relationship will be set
    /// B. Attempt to merge the current Branch with the Previous Branch
    /// C. Return the collection of Reduced + Merged Nodes
    ///
    func process(branches: [Branch]) -> [Node] {
        let sorted = sort(branches: branches)
        var merged = [Node]()
        var previous: Branch?

        for branch in sorted {
            if let left = previous , let current = merge(left: left, right: branch) {
                previous = current
                continue
            }

            let reduced = reduce(nodes: branch.nodes.reversed(), leaves: branch.leaves)
            merged.append(contentsOf: reduced)
            previous = branch
        }

        return merged
    }


    /// Attempts to merge the Right Branch into the Left Branch. On success, we'll return a newly created
    /// branch, containing the 'Left-Matched-Elements' + 'Right-Unmathed-Elements' + 'Right-Leaves'.
    ///
    private func merge(left: Branch, right: Branch) -> Branch? {
        guard let mergeableCandidate = findMergeableNodes(left: left.nodes, right: right.nodes, blocklevelEnforced: false),
            let target = mergeableCandidate.last?.left
        else {
            return nil
        }

        let mergeableLeftNodes = mergeableCandidate.flatMap { $0.left }
        let mergeableRightNodes = mergeableCandidate.flatMap { $0.right }

        // Reduce: Non Mergeable Right Subtree
        let nonMergeableRightNodesSet = Set(right.nodes).subtracting(mergeableRightNodes)
        let nonMergeableRightNodes = Array(nonMergeableRightNodesSet)

        let source = reduce(nodes: nonMergeableRightNodes, leaves: right.leaves)

        // Merge: Move the 'Non Mergeable Right Subtree' to the left merging spot
        target.children += source

        // Regen: Branch with the actual used instances!
        let mergedNodes = mergeableLeftNodes + nonMergeableRightNodes
        return Branch(nodes: mergedNodes, leaves: right.leaves)
    }


    /// Arranges a collection of Branches in a (Hopefully) "Defragmented" way:
    ///
    /// - Nodes will be sorted 'By Length'. Longer nodes will appear on top
    /// - Nodes that existed in the previous branch are expected to maintain the exact same position
    ///
    private func sort(branches: [Branch]) -> [Branch] {
        var output = [Branch]()
        var previous = [ElementNode]()

        for (index, branch) in branches.enumerated() {
            let lengths = lengthOfElements(atColumnIndex: index, in: branches)

            // Split Duplicates: Nodes that existed in the previous collection (while retaining their original position!)
            let (sorted, unsorted) = splitDuplicateNodes(in: branch.nodes, comparingWith: previous)

            // Sort 'Branch New Items' + Consolidate
            let consolidated = sorted + unsorted.sorted(by: { lengths[$0]! > lengths[$1]! })

            let updated = Branch(nodes: consolidated, leaves: branch.leaves)
            output.append(updated)
            previous = consolidated
        }

        return output
    }


    /// Splits a collection of Nodes in two groups: 'Nodes that also exist in a Reference Collection', and
    /// 'Completely New Nodes'. 
    ///
    /// *Note*: The order of those Pre Existing nodes will be arranged in the exact same way as they appear
    /// in the reference collection.
    ///
    private func splitDuplicateNodes(in current: [ElementNode], comparingWith previous: [ElementNode]) -> ([ElementNode], [ElementNode]) {
        var duplicates = [ElementNode]()
        var nonDuplicates = [ElementNode]()

        for node in previous where current.contains(node) {
            guard let index = current.index(of: node) else {
                continue
            }

            let target = current[index]
            duplicates.append(target)
        }

        for node in current where !duplicates.contains(node) {
            nonDuplicates.append(node)
        }

        return (duplicates, nonDuplicates)
    }


    /// Determines the length of (ALL) of the Nodes at a specified Column, given a collection of Branches.
    ///
    private func lengthOfElements(atColumnIndex index: Int, in branches: [Branch]) -> [ElementNode: Int] {
        var lengths = [ElementNode: Int]()
        var rightmost = branches
        rightmost.removeFirst(index)

        for node in branches[index].nodes {
            lengths[node] = length(of: node, in: rightmost)
        }

        return lengths
    }


    /// Determines the length of a Node, given a collection of branches.
    ///
    private func length(of element: ElementNode, in branches: [Branch]) -> Int {
        var length = 0

        for branch in branches {
            if !branch.nodes.contains(element) {
                break
            }

            length += 1
        }

        return length
    }
}


// MARK: - Merge: Paragraphs
//
private extension NSAttributedStringToNodes {

    /// Attempts to merge the Right array of Element Nodes (Paragraph Level) into the Left array of Nodes.
    ///
    /// - We expect two collections of Mergeable Elements: Paragraph Level, with matching Names + Attributes
    ///
    func merge(left: [ElementNode], right: [ElementNode]) -> Bool {
        guard let mergeableCandidates = findMergeableNodes(left: left, right: right) else {
            return false
        }

        guard let (leftMerger, rightMerger) = mergeablePair(from: mergeableCandidates) else {
            return false
        }

        leftMerger.children += rightMerger.children

        return true
    }


    /// Finds the last valid Mergeable Pair within a collection of mergeable nodes
    ///
    /// - Last LI item is never merged
    /// - Last 'Mergeable' element is never merged (ie. <h1>Hello\nWorld</h1> >> <h1>Hello</h1><h1>World</h1>
    ///
    private func mergeablePair(from mergeableNodes: [MergeablePair]) -> MergeablePair? {

        // Business logic: The last mergeable node is never merged, so we need more than 1 node to continue.
        //
        guard mergeableNodes.count > 1,
            let lastNodeName = mergeableNodes.last?.left.name
        else {
            return nil
        }

        var mergeCandidates = mergeableNodes.dropLast()
        
        if lastNodeName != "li" {
            mergeCandidates = prefix(upToLast: "li", from: mergeCandidates)
        }
        
        return mergeCandidates.last
    }


    /// Slices the specified array until the last LI node. For instance:
    ///
    /// - Input: [.ul, .li, .h1]
    ///
    /// - Output: [.ul]
    ///
    private func prefix(upToLast name: String, from nodes: ArraySlice<MergeablePair>) -> ArraySlice<MergeablePair> {
        var lastItemIndex: Int?
        for (index, node) in nodes.enumerated().reversed() where node.left.name == name {
            lastItemIndex = index
            break
        }

        guard let sliceIndex = lastItemIndex else {
            return nodes
        }

        return nodes[0..<sliceIndex]
    }
}


// MARK: - Paragraph Nodes Extraction
//
extension NSAttributedStringToNodes {

    /// Returns the "Rightmost" Blocklevel Node from a collection fo nodes.
    ///
    func rightmostParagraphStyleElements(from nodes: [Node]) -> [ElementNode] {
        return paragraphStyleElements(from: nodes) { children in
            return children.last
        }
    }


    /// Returns the "Leftmost" Blocklevel Node from a collection fo nodes.
    ///
    func leftmostParagraphStyleElements(from nodes: [Node]) -> [ElementNode] {
        return paragraphStyleElements(from: nodes) { children in
            return children.first
        }
    }


    /// Returns a children Blocklevel Node from a collection of nodes, using a Child Picker to determine the
    /// navigational-direction.
    ///
    private func paragraphStyleElements(from nodes: [Node], childPicker: (([Node]) -> Node?)) -> [ElementNode] {
        var elements = [ElementNode]()
        var nextElement = childPicker(nodes) as? ElementNode

        while let currentElement = nextElement {
            guard currentElement.isBlockLevelElement() else {
                break
            }

            elements.append(currentElement)
            nextElement = childPicker(currentElement.children) as? ElementNode
        }

        return elements
    }
}


// MARK: - Paragraph Nodes: Alloc'ation
//
private extension NSAttributedStringToNodes {

    /// Extracts the ElementNodes contained within a Paragraph's AttributedString.
    ///
    /// - Parameters:
    ///     - attrString: Paragraph's AttributedString from which we intend to extract the ElementNode
    ///
    /// - Returns: ElementNode representing the specified Paragraph.
    ///
    func createParagraphNodes(from attrString: NSAttributedString) -> [ElementNode] {
        guard let paragraphStyle = attrString.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? ParagraphStyle else {
            return []
        }

        var paragraphNodes = [ElementNode]()

        for property in paragraphStyle.properties.reversed() {
            switch property {
            case let blockquote as Blockquote:
                paragraphNodes += processBlockquoteStyle(blockquote: blockquote)

            case let header as Header:
                paragraphNodes += processHeaderStyle(header: header)

            case let list as TextList:
                paragraphNodes += processListStyle(list: list)

            case let paragraph as HTMLParagraph:
                paragraphNodes += processParagraphStyle(paragraph: paragraph)

            case let pre as HTMLPre:
                paragraphNodes += processPreStyle(pre: pre)

            default:
                continue
            }
        }

        return paragraphNodes
    }


    /// Extracts all of the Blockquote Elements contained within a collection of Attributes.
    ///
    private func processBlockquoteStyle(blockquote: Blockquote) -> [ElementNode] {
        let node = blockquote.representation?.toNode() ?? ElementNode(type: .blockquote)
        return [node]
    }


    /// Extracts all of the Header Elements contained within a collection of Attributes.
    ///
    private func processHeaderStyle(header: Header) -> [ElementNode] {
        guard let type = ElementNode.elementTypeForHeaderLevel(header.level.rawValue) else {
            return []
        }

        let node = header.representation?.toNode() ?? ElementNode(type: type)
        return [node]
    }


    /// Extracts all of the List Elements contained within a collection of Attributes.
    ///
    private func processListStyle(list: TextList) -> [ElementNode] {
        let elementType = list.style == .ordered ? StandardElementType.ol : StandardElementType.ul
        let listElement = list.representation?.toNode() ?? ElementNode(type: elementType)
        let itemElement = ElementNode(type: .li)

        // TODO: LI needs it's Original Attributes!!
        return [itemElement, listElement]
    }


    /// Extracts all of the Paragraph Elements contained within a collection of Attributes.
    ///
    private func processParagraphStyle(paragraph: HTMLParagraph) -> [ElementNode] {
        let node = paragraph.representation?.toNode() ?? ElementNode(type: .p)
        return [node]
    }


    /// Extracts all of the Pre Elements contained within a collection of Attributes.
    ///
    private func processPreStyle(pre: HTMLPre) -> [ElementNode] {
        let node = pre.representation?.toNode() ?? ElementNode(type: .pre)
        return [node]
    }
}


// MARK: - Style Nodes: Alloc'ation
//
private extension NSAttributedStringToNodes {

    /// Extracts all of the Style Nodes contained within a collection of AttributedString Attributes.
    ///
    /// - Parameters:
    ///     - attrs: Collection of attributes that should be converted.
    ///
    /// - Returns: Style Nodes contained within the specified collection of attributes
    ///
    func createStyleNodes(from attributes: [String: Any]) -> [ElementNode] {
        var nodes = [ElementNode]()

        nodes += processFontStyle(in: attributes)
        nodes += processLinkStyle(in: attributes)
        nodes += processStrikethruStyle(in: attributes)
        nodes += processUnderlineStyle(in: attributes)
        nodes += processUnsupportedHTML(in: attributes)

        return nodes
    }


    /// Extracts all of the Font Elements contained within a collection of Attributes.
    ///
    private func processFontStyle(in attributes: [String: Any]) -> [ElementNode] {
        guard let font = attributes[NSFontAttributeName] as? UIFont else {
            return []
        }

        var nodes = [ElementNode]()

        if font.containsTraits(.traitBold) {
            let representation = attributes[BoldFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
            let node = representation?.toNode() ?? ElementNode(type: .b)

            nodes.append(node)
        }

        if font.containsTraits(.traitItalic) {
            let representation = attributes[ItalicFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
            let node = representation?.toNode() ?? ElementNode(type: .i)

            nodes.append(node)
        }

        return nodes
    }


    /// Extracts all of the Link Elements contained within a collection of Attributes.
    ///
    private func processLinkStyle(in attributes: [String: Any]) -> [ElementNode] {
        guard let url = attributes[NSLinkAttributeName] as? URL else {
            return []
        }

        let representation = attributes[LinkFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .a)
        node.updateAttribute(named: "href", value: url.absoluteString)

        return [node]
    }


    /// Extracts all of the Strike Elements contained within a collection of Attributes.
    ///
    private func processStrikethruStyle(in attributes: [String: Any]) -> [ElementNode] {
        guard attributes[NSStrikethroughStyleAttributeName] != nil else {
            return []
        }

        let representation = attributes[StrikethroughFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .strike)

        return [node]
    }


    /// Extracts all of the Underline Elements contained within a collection of Attributes.
    ///
    private func processUnderlineStyle(in attributes: [String: Any]) -> [ElementNode] {
        guard attributes[NSUnderlineStyleAttributeName] != nil else {
            return []
        }

        let representation = attributes[UnderlineFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .u)

        return [node]
    }


    /// Extracts all of the Unsupported HTML Snippets contained within a collection of Attributes.
    ///
    private func processUnsupportedHTML(in attributes: [String: Any]) -> [ElementNode] {
        guard let unsupported = attributes[UnsupportedHTMLAttributeName] as? UnsupportedHTML else {
            return []
        }

        return unsupported.elements.reversed().flatMap({ element in
            return element.toNode()
        })
    }
}


// MARK: - Leaf Nodes: Alloc'ation
//
private extension NSAttributedStringToNodes {

    /// Extract all of the Leaf Nodes contained within an Attributed String. We consider the following as Leaf:
    /// Plain Text, Attachments of any kind [Line, Comment, HTML, Image].
    ///
    /// - Parameter attrString: AttributedString that should be converted.
    ///
    /// - Returns: Leaf Nodes contained within the specified collection of attributes
    ///
    func createLeafNodes(from attrString: NSAttributedString) -> [Node] {
        var nodes = [Node]()

        nodes += processLineAttachment(from: attrString)
        nodes += processCommentAttachment(from: attrString)
        nodes += processHtmlAttachment(from: attrString)
        nodes += processImageAttachment(from: attrString)
        nodes += processVideoAttachment(from: attrString)

        return nodes.isEmpty ? processTextNodes(from: attrString.string) : nodes
    }

    /// Converts a Line Attachment into it's representing nodes.
    ///
    private func processLineAttachment(from attrString: NSAttributedString) -> [Node] {
        guard attrString.attribute(NSAttachmentAttributeName, at: 0, effectiveRange: nil) is LineAttachment else {
            return []
        }

        let range = attrString.rangeOfEntireString
        let representation = attrString.attribute(HRFormatter.htmlRepresentationKey, at: 0, longestEffectiveRange: nil, in: range) as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .hr)
        return [node]
    }


    /// Converts a Comment Attachment into it's representing nodes.
    ///
    private func processCommentAttachment(from attrString: NSAttributedString) -> [Node] {
        guard let attachment = attrString.attribute(NSAttachmentAttributeName, at: 0, effectiveRange: nil) as? CommentAttachment else {
            return []
        }

        let node = CommentNode(text: attachment.text)
        return [node]
    }


    /// Converts an HTML Attachment into it's representing nodes.
    ///
    private func processHtmlAttachment(from attrString: NSAttributedString) -> [Node] {
        guard let attachment = attrString.attribute(NSAttachmentAttributeName, at: 0, effectiveRange: nil) as? HTMLAttachment else {
            return []
        }

        let converter = Libxml2.In.HTMLConverter()

        let rootNode = converter.convert(attachment.rawHTML)

        guard let firstChild = rootNode.children.first else {
            return processTextNodes(from: attachment.rawHTML)
        }

        guard rootNode.children.count == 1 else {
            let node = ElementNode(type: .span, attributes: [], children: rootNode.children)
            return [node]
        }

        return [firstChild]
    }


    /// Converts an Image Attachment into it's representing nodes.
    ///
    private func processImageAttachment(from attrString: NSAttributedString) -> [Node] {
        guard let attachment = attrString.attribute(NSAttachmentAttributeName, at: 0, effectiveRange: nil) as? ImageAttachment else {
            return []
        }

        let range = attrString.rangeOfEntireString
        let representation = attrString.attribute(ImageFormatter.htmlRepresentationKey, at: 0, longestEffectiveRange: nil, in: range) as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .img)

        if let attribute = imageSourceAttribute(from: attachment) {
            node.updateAttribute(named: attribute.name, value: attribute.value)
        }

        if let attribute = imageClassAttribute(from: attachment) {
            node.updateAttribute(named: attribute.name, value: attribute.value)
        }

        return [node]
    }

    /// Converts an Video Attachment into it's representing nodes.
    ///
    private func processVideoAttachment(from attrString: NSAttributedString) -> [Node] {
        guard let attachment = attrString.attribute(NSAttachmentAttributeName, at: 0, effectiveRange: nil) as? VideoAttachment else {
            return []
        }

        let range = attrString.rangeOfEntireString
        let representation = attrString.attribute(VideoFormatter.htmlRepresentationKey, at: 0, longestEffectiveRange: nil, in: range) as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .video)

        if let attribute = videoSourceAttribute(from: attachment) {
            node.updateAttribute(named: attribute.name, value: attribute.value)
        }

        if let attribute = videoPosterAttribute(from: attachment) {
            node.updateAttribute(named: attribute.name, value: attribute.value)
        }

        for (key,value) in attachment.namedAttributes {
            node.updateAttribute(named: key, value: value)
        }

        return [node]
    }


    /// Converts a String into it's representing nodes.
    ///
    private func processTextNodes(from text: String) -> [Node] {
        let substrings = text.components(separatedBy: String(.lineSeparator))
        var output = [Node]()

        for (index, substring) in substrings.enumerated() {

            output.append(TextNode(text: substring))

            if index < substrings.count - 1 {
                output.append(ElementNode(type: .br))
            }
        }
        
        return output
    }


    /// Extracts the Video Source Attribute from a VideoAttachment Instance.
    ///
    private func videoSourceAttribute(from attachment: VideoAttachment) -> StringAttribute? {
        guard let source = attachment.srcURL?.absoluteString else {
            return nil
        }

        return StringAttribute(name: "src", value: source)
    }


    /// Extracts the Video Poster Attribute from a VideoAttachment Instance.
    ///
    private func videoPosterAttribute(from attachment: VideoAttachment) -> StringAttribute? {
        guard let poster = attachment.posterURL?.absoluteString else {
            return nil
        }

        return StringAttribute(name: "poster", value: poster)
    }


    /// Extracts the src attribute from an ImageAttachment Instance.
    ///
    private func imageSourceAttribute(from attachment: ImageAttachment) -> StringAttribute? {
        guard let source = attachment.url?.absoluteString else {
            return nil
        }

        return StringAttribute(name: "src", value: source)
    }


    /// Extracts the class attribute from an ImageAttachment Instance.
    ///
    private func imageClassAttribute(from attachment: ImageAttachment) -> StringAttribute? {
        var style = String()
        if attachment.alignment != .center {
            style += attachment.alignment.htmlString()
        }

        if attachment.size != .full {
            style += style.isEmpty ? String() : String(.space)
            style += attachment.size.htmlString()
        }

        guard !style.isEmpty else {
            return nil
        }

        return StringAttribute(name: "class", value: style)
    }
}
