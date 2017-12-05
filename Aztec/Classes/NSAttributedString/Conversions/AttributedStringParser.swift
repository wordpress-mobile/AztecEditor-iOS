import Foundation
import UIKit
import libxml2

/// Parses an attributed string into an HTML tree.
///
class AttributedStringParser {

    /// Parses an attributed string and returns the corresponding HTML tree.
    ///
    /// - Parameters:
    ///     - attrString: the attributed string to parse
    ///
    /// - Returns: the HTML tree.
    ///
    func parse(_ attrString: NSAttributedString) -> RootNode {
        var nodes = [Node]()
        var previous: [Node]?

        attrString.enumerateParagraphRanges(spanning: attrString.rangeOfEntireString) { (paragraphRange, enclosingRange) in
            let children = createNodes(from: attrString, paragraphRange: paragraphRange, enclosingRange: enclosingRange)

            if let previous = previous {
                let left = rightmostParagraphStyleElements(from: previous)
                let right = leftmostParagraphStyleElements(from: children)

                guard !merge(left: left, right: right) else {
                    return
                }
            }

            nodes += children
            previous = children
        }

        return RootNode(children: nodes)
    }


    /// Converts a Substring, defined by it's paragraphRange and enclosingRange, into a collection of Nodes,
    /// representing the internal HTML Entities.
    ///
    /// Note:
    /// Whenever the paragraph defined by the paragraphRange is zero, we'll proceed extracting all of the attributes
    /// present in the Enclosing Range. Otherwise, we might loose data!
    ///
    /// - Parameter:
    ///     - attrString: Reference to the document to be converted.
    ///     - paragraphRange: Defines the Paragraph Range to be converted into Nodes.
    ///     - enclosingRange: Defines the Paragraph's Enclosing Range (containing newline characters).
    ///
    /// - Returns: Array of Node instances.
    ///
    private func createNodes(from attrString: NSAttributedString, paragraphRange: NSRange, enclosingRange: NSRange) -> [Node] {
        guard paragraphRange.length > 0 else {
            let attributes = attrString.attributes(at: enclosingRange.location, longestEffectiveRange: nil, in: enclosingRange)
            return createNodes(from: attributes)
        }

        let paragraph = attrString.attributedSubstring(from: paragraphRange)
        return createNodes(from: paragraph)
    }


    /// Converts a *Paragraph* into a collection of Nodes, representing the internal HTML Entities.
    ///
    /// - Parameter paragraph: Paragraph's Attributed String that should be converted.
    ///
    /// - Returns: Array of Node instances.
    ///
    private func createNodes(from paragraph: NSAttributedString) -> [Node] {
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


    /// Converts a collection of Attributes into their Node(s) representation.
    ///
    /// - Parameter attributes: Attributes to be mapped into nodes
    ///
    /// - Returns: Array of Node instances.
    ///
    private func createNodes(from attributes: [AttributedStringKey: Any]) -> [Node] {
        let nodes = createParagraphNodes(from: attributes) + createStyleNodes(from: attributes)

        return nodes.reversed().reduce([]) { (result, node) in
            node.children = result
            return [node]
        }
    }
}


// MARK: - Merge: Helpers
//
private extension AttributedStringParser {

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
private extension AttributedStringParser {

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
    @inline(__always)
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
    @inline(__always)
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
    @inline(__always)
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
private extension AttributedStringParser {

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

        if lastNodeName != StandardElementType.li.rawValue {
            mergeCandidates = prefix(upToLast: StandardElementType.li.rawValue, from: mergeCandidates)
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
extension AttributedStringParser {

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


// MARK: - Paragraph Nodes: Allocation
//
private extension AttributedStringParser {

    /// Extracts the ElementNodes contained within a Paragraph's AttributedString.
    ///
    /// - Parameters:
    ///     - attrString: Paragraph's AttributedString from which we intend to extract the ElementNode
    ///
    /// - Returns: ElementNode representing the specified Paragraph.
    ///
    func createParagraphNodes(from paragraph: NSAttributedString) -> [ElementNode] {

        // If we're unable to find any paragraph-level styles, we return an HTML paragraph element as
        // default.  The reason behind this decision is that no text can exist outside block-level
        // elements in Aztec.
        //
        // See here for more info:
        // https://github.com/wordpress-mobile/AztecEditor-iOS/issues/667
        //
        guard let paragraphStyle = paragraph.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? ParagraphStyle,
            paragraphStyle.properties.count > 0
        else {
            return [ElementNode(type: .p)]
        }

        return createParagraphNodes(from: paragraphStyle)
    }


    /// Extracts the ElementNodes contained within a Paragraph's AttributedString.
    ///
    /// - Parameters:
    ///     - attributes: Paragraph's Attributes from which we intend to extract the ElementNode
    ///
    /// - Returns: ElementNode representing the specified Paragraph.
    ///
    func createParagraphNodes(from attributes: [AttributedStringKey: Any]) -> [ElementNode] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
            paragraphStyle.properties.count > 0 else {
                return [ElementNode(type: .p)]
        }

        return createParagraphNodes(from: paragraphStyle)
    }


    /// Extracts the ElementNodes contained within a ParagraphStyle Instance.
    ///
    /// - Parameters:
    ///     - paragraphStyle: ParagraphStyle from which we intend to extract the ElementNode
    ///
    /// - Returns: ElementNode representing the specified Paragraph.
    ///
    private func createParagraphNodes(from paragraphStyle: ParagraphStyle) -> [ElementNode] {
        var paragraphNodes = [ElementNode]()

        for property in paragraphStyle.properties.reversed() {
            switch property {
            case let blockquote as Blockquote:
                let element = processBlockquoteStyle(blockquote: blockquote)
                paragraphNodes.append(element)

            case let header as Header:
                guard let element = processHeaderStyle(header: header) else {
                    continue
                }

                paragraphNodes.append(element)

            case let list as TextList:
                let elements = processListStyle(list: list)
                paragraphNodes += elements

            case let div as HTMLDiv:
                let element = processDivStyle(div: div)
                paragraphNodes.append(element)

            case let paragraph as HTMLParagraph:
                let element = processParagraphStyle(paragraph: paragraph)
                paragraphNodes.append(element)

            case let pre as HTMLPre:
                let element = processPreStyle(pre: pre)
                paragraphNodes.append(element)

            default:
                continue
            }
        }

        return paragraphNodes
    }


    /// Extracts all of the Blockquote Elements contained within a collection of Attributes.
    ///
    private func processBlockquoteStyle(blockquote: Blockquote) -> ElementNode {

        guard let representation = blockquote.representation,
            case let .element(element) = representation.kind else {

            return ElementNode(type: .blockquote)
        }

        return element.toElementNode()
    }


    /// Extracts all of the Div Elements contained within a collection of Attributes.
    ///
    private func processDivStyle(div: HTMLDiv) -> ElementNode {

        guard let representation = div.representation,
            case let .element(representationElement) = representation.kind
        else {
            return ElementNode(type: .div)
        }

        return representationElement.toElementNode()
    }


    /// Extracts all of the Header Elements contained within a collection of Attributes.
    ///
    private func processHeaderStyle(header: Header) -> ElementNode? {
        guard let type = ElementNode.elementTypeForHeaderLevel(header.level.rawValue) else {
            return nil
        }

        guard let representation = header.representation,
            case let .element(element) = representation.kind else {

                return ElementNode(type: type)
        }

        return element.toElementNode()
    }


    /// Extracts all of the List Elements contained within a collection of Attributes.
    ///
    private func processListStyle(list: TextList) -> [ElementNode] {
        let listType = list.style == .ordered ? StandardElementType.ol : StandardElementType.ul

        let listElement: ElementNode
        let lineElement = ElementNode(type: .li)

        if let representation = list.representation,
            case let .element(element) = representation.kind {

            listElement = element.toElementNode()
        } else {
            listElement = ElementNode(type: listType)
        }

        return [lineElement, listElement]
    }


    /// Extracts all of the Paragraph Elements contained within a collection of Attributes.
    ///
    private func processParagraphStyle(paragraph: HTMLParagraph) -> ElementNode {

        let element: ElementNode

        if let representation = paragraph.representation,
            case let .element(representationElement) = representation.kind {

            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .p)
        }

        return element
    }


    /// Extracts all of the Pre Elements contained within a collection of Attributes.
    ///
    private func processPreStyle(pre: HTMLPre) -> ElementNode {

        let element: ElementNode

        if let representation = pre.representation,
            case let .element(representationElement) = representation.kind {

            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .pre)
        }

        return element
    }
}


// MARK: - Style Nodes: Allocation
//
private extension AttributedStringParser {

    /// Extracts all of the Style Nodes contained within a collection of AttributedString Attributes.
    ///
    /// - Parameters:
    ///     - attrs: Collection of attributes that should be converted.
    ///
    /// - Returns: Style Nodes contained within the specified collection of attributes
    ///
    func createStyleNodes(from attributes: [AttributedStringKey: Any]) -> [ElementNode] {
        var nodes = [ElementNode]()

        if let element = processBold(in: attributes) {
            nodes.append(element)
        }

        if let element = processItalic(in: attributes) {
            nodes.append(element)
        }

        if let element = processLinkStyle(in: attributes) {
            nodes.append(element)
        }

        if let element = processStrikethruStyle(in: attributes) {
            nodes.append(element)
        }

        if let element = processUnderlineStyle(in: attributes) {
            nodes.append(element)
        }

        nodes += processUnsupportedHTML(in: attributes)

        return nodes
    }

    private func processBold(in attributes: [AttributedStringKey: Any]) -> ElementNode? {
        guard let font = attributes[.font] as? UIFont,
            font.containsTraits(.traitBold) else {
                return nil
        }

        let element: ElementNode

        if let representation = attributes[AttributedStringKey.boldHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .strong)
        }

        return element
    }


    private func processItalic(in attributes: [AttributedStringKey: Any]) -> ElementNode? {
        guard let font = attributes[.font] as? UIFont,
            font.containsTraits(.traitItalic) else {
                return nil
        }

        let element: ElementNode

        if let representation = attributes[AttributedStringKey.italicHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .em)
        }

        return element
    }

    /// Extracts all of the Link Elements contained within a collection of Attributes.
    ///
    private func processLinkStyle(in attributes: [AttributedStringKey: Any]) -> ElementNode? {
        var urlString = ""
        if let url = attributes[AttributedStringKey.link] as? URL {
            urlString = url.absoluteString
        } else if let link = attributes[AttributedStringKey.link] as? String {
            urlString = link
        } else {
            return nil
        }

        let element: ElementNode

        if let representation = attributes[.linkHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .a)
        }

        element.updateAttribute(named: HTMLLinkAttribute.Href.rawValue, value: .string(urlString))

        return element
    }


    /// Extracts all of the Strike Elements contained within a collection of Attributes.
    ///
    private func processStrikethruStyle(in attributes: [AttributedStringKey: Any]) -> ElementNode? {
        guard attributes[AttributedStringKey.strikethroughStyle] != nil else {
            return nil
        }

        if let representation = attributes[AttributedStringKey.strikethroughHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            return representationElement.toElementNode()
        }

        return ElementNode(type: .strike)
    }


    /// Extracts all of the Underline Elements contained within a collection of Attributes.
    ///
    private func processUnderlineStyle(in attributes: [AttributedStringKey: Any]) -> ElementNode? {
        guard attributes[.underlineStyle] != nil else {
            return nil
        }

        if let representation = attributes[.underlineHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            return representationElement.toElementNode()
        }

        return ElementNode(type: .u)
    }


    /// Extracts all of the Unsupported HTML Snippets contained within a collection of Attributes.
    ///
    private func processUnsupportedHTML(in attributes: [AttributedStringKey: Any]) -> [ElementNode] {
        guard let unsupportedHTML = attributes[.unsupportedHtml] as? UnsupportedHTML else {
            return []
        }

        return unsupportedHTML.representations.map { representation in
            return representation.toElementNode()
        }
    }
}


// MARK: - Leaf Nodes: Allocation
//
private extension AttributedStringParser {

    /// Extract all of the Leaf Nodes contained within an Attributed String. We consider the following as Leaf:
    /// Plain Text, Attachments of any kind [Line, Comment, HTML, Image].
    ///
    /// - Parameter attrString: AttributedString that should be converted.
    ///
    /// - Returns: Leaf Nodes contained within the specified collection of attributes
    ///
    func createLeafNodes(from attrString: NSAttributedString) -> [Node] {
        var nodes = [Node]()

        if let attachment = processLineAttachment(from: attrString) {
            nodes.append(attachment)
        }

        if let attachment = processCommentAttachment(from: attrString) {
            nodes.append(attachment)
        }

        nodes += processHtmlAttachment(from: attrString)

        if let attachment = processImageAttachment(from: attrString) {
            nodes.append(attachment)
        }

        if let attachment = processVideoAttachment(from: attrString) {
            nodes.append(attachment)
        }

        return nodes.isEmpty ? processTextNodes(from: attrString.string) : nodes
    }

    /// Converts a Line Attachment into it's representing nodes.
    ///
    private func processLineAttachment(from attrString: NSAttributedString) -> ElementNode? {
        guard attrString.attribute(.attachment, at: 0, effectiveRange: nil) is LineAttachment else {
            return nil
        }

        let element: ElementNode
        let range = attrString.rangeOfEntireString

        if let representation = attrString.attribute(AttributedStringKey.hrHtmlRepresentation, at: 0, longestEffectiveRange: nil, in: range) as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .hr)
        }

        return element
    }


    /// Converts a Comment Attachment into it's representing nodes.
    ///
    private func processCommentAttachment(from attrString: NSAttributedString) -> Node? {
        guard let attachment = attrString.attribute(.attachment, at: 0, effectiveRange: nil) as? CommentAttachment else {
            return nil
        }

        let node = CommentNode(text: attachment.text)
        return node
    }


    /// Converts an HTML Attachment into it's representing nodes.
    ///
    private func processHtmlAttachment(from attrString: NSAttributedString) -> [Node] {
        guard let attachment = attrString.attribute(.attachment, at: 0, effectiveRange: nil) as? HTMLAttachment else {
            return []
        }

        let htmlParser = HTMLParser()

        let rootNode = htmlParser.parse(attachment.rawHTML)

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
    private func processImageAttachment(from attrString: NSAttributedString) -> ElementNode? {
        guard let attachment = attrString.attribute(.attachment, at: 0, effectiveRange: nil) as? ImageAttachment else {
            return nil
        }

        let imageElement: ElementNode
        let range = attrString.rangeOfEntireString

        if let representation = attrString.attribute(.imageHtmlRepresentation, at: 0, longestEffectiveRange: nil, in: range) as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            imageElement = representationElement.toElementNode()
        } else {
            imageElement = ElementNode(type: .img)
        }

        if let attribute = imageSourceAttribute(from: attachment) {
            imageElement.updateAttribute(named: attribute.name, value: attribute.value)
        }

        if let attribute = imageClassAttribute(from: attachment) {
            imageElement.updateAttribute(named: attribute.name, value: attribute.value)
        }

        for (key,value) in attachment.extraAttributes {
            var finalValue = value
            if key == "class", let baseValue = imageElement.stringValueForAttribute(named: "class"){
                let baseComponents = Set(baseValue.components(separatedBy: " "))
                let extraComponents = Set(value.components(separatedBy: " "))
                finalValue = baseComponents.union(extraComponents).joined(separator: " ")
            }
            imageElement.updateAttribute(named: key, value: .string(finalValue))
        }        

        /// Special Case:
        /// - Extract the ImageAttachment's caption field
        /// - Create the Caption Element
        /// - Wrap everything within a Figure tag!
        ///
        /// Note that the Figure element is handled by the HTMLFigureFormatter.
        ///
        if let figcaptionElement = figcaptionElement(from: attachment) {
            return ElementNode(type: .figure, attributes: [], children: [imageElement, figcaptionElement])
        }

        return imageElement
    }


    /// Converts an Video Attachment into it's representing nodes.
    ///
    private func processVideoAttachment(from attrString: NSAttributedString) -> ElementNode? {
        guard let attachment = attrString.attribute(.attachment, at: 0, effectiveRange: nil) as? VideoAttachment else {
            return nil
        }

        let element: ElementNode
        let range = attrString.rangeOfEntireString

        if let representation = attrString.attribute(AttributedStringKey.videoHtmlRepresentation, at: 0, longestEffectiveRange: nil, in: range) as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .video)
        }

        if let attribute = videoSourceAttribute(from: attachment) {
            element.updateAttribute(named: attribute.name, value: attribute.value)
        }

        if let attribute = videoPosterAttribute(from: attachment) {
            element.updateAttribute(named: attribute.name, value: attribute.value)
        }

        for (key,value) in attachment.extraAttributes {
            element.updateAttribute(named: key, value: .string(value))
        }

        return element
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
    private func videoSourceAttribute(from attachment: VideoAttachment) -> Attribute? {
        guard let source = attachment.srcURL?.absoluteString else {
            return nil
        }

        return Attribute(name: "src", value: .string(source))
    }


    /// Extracts the Video Poster Attribute from a VideoAttachment Instance.
    ///
    private func videoPosterAttribute(from attachment: VideoAttachment) -> Attribute? {
        guard let poster = attachment.posterURL?.absoluteString else {
            return nil
        }

        return Attribute(name: "poster", value: .string(poster))
    }


    /// Extracts the src attribute from an ImageAttachment Instance.
    ///
    private func imageSourceAttribute(from attachment: ImageAttachment) -> Attribute? {
        guard let source = attachment.url?.absoluteString else {
            return nil
        }

        return Attribute(name: "src", value: .string(source))
    }


    /// Extracts the class attribute from an ImageAttachment Instance.
    ///
    private func imageClassAttribute(from attachment: ImageAttachment) -> Attribute? {
        var style = String()
        if attachment.alignment != .center {
            style += attachment.alignment.htmlString()
        }
        
        if attachment.size != .none {
            style += style.isEmpty ? String() : String(.space)
            style += attachment.size.htmlString()
        }

        guard !style.isEmpty else {
            return nil
        }

        return Attribute(name: "class", value: .string(style))
    }


    /// Extracts the Figcaption Element from an ImageAttachment Instance.
    ///
    private func figcaptionElement(from attachment: ImageAttachment) -> ElementNode? {
        guard let caption = attachment.caption,
            let paragraph = AttributedStringParser().parse(caption).firstChild(ofType: .p)
            else {
                return nil
        }

        return ElementNode(type: .figcaption, attributes: [], children: paragraph.children)
    }
}
