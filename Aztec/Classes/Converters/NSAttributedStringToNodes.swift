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
        var children = [Node]()

        guard paragraph.length > 0 else {
            return []
        }

        paragraph.enumerateAttributes(in: paragraph.rangeOfEntireString, options: []) { (attrs, range, _) in

            let substring = paragraph.attributedSubstring(from: range)
            let leaves = createLeafNodes(from: substring)
            let styles = createStyleNodes(from: attrs)
// TODO: Remove. Recreating old behavior
            var innerChildren = leaves
            for style in styles.reversed() {
                style.children = innerChildren
                innerChildren = [style]
            }

            let target = innerChildren.isEmpty ? leaves : innerChildren
// TODO: Remove. Recreating old behavior
            children.append(contentsOf: target)
        }

        guard let paragraphElement = createParagraphElement(from: paragraph, children: children) else {
            return children
        }

        return [paragraphElement]
    }
}


// MARK: - Merge
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


    /// Defines a pair of Nodes that can be merged
    ///
    typealias MergeablePair = (left: ElementNode, right: ElementNode)


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


    /// Finds the Deepest node that can be merged "Right to Left", and returns the Left / Right matching touple, if any.
    ///
    private func findMergeableNodes(left: [ElementNode], right: [ElementNode]) -> [MergeablePair]? {
        var currentIndex = 0
        var matching = [MergeablePair]()

        while currentIndex < left.count && currentIndex < right.count {
            let left = left[currentIndex]
            let right = right[currentIndex]

            guard left.canMergeChildren(of: right) else {
                break
            }

            let pair = MergeablePair(left: left, right: right)
            matching.append(pair)
            currentIndex += 1
        }
        
        return matching.isEmpty ? nil : matching
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


// MARK: - Node Creation
//
private extension NSAttributedStringToNodes {

    /// Extracts the ElementNode contained within a Paragraph's AttributedString.
    ///
    /// - Parameters:
    ///     - attrString: Paragraph's AttributedString from which we intend to extract the ElementNode
    ///     - children: Array of Node instances to be set as children
    ///
    /// - Returns: ElementNode representing the specified Paragraph.
    ///
    func createParagraphElement(from attrString: NSAttributedString, children: [Node]) -> ElementNode? {
        guard let paragraphStyle = attrString.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? ParagraphStyle else {
            return nil
        }

        var lastNodes: [ElementNode]?

        enumerateParagraphNodes(in: paragraphStyle) { node in
            node.children = lastNodes ?? children
            lastNodes = [node]
        }

        return lastNodes?.first
    }
}


// MARK: - Paragraph Nodes: Alloc'ation
//
private extension NSAttributedStringToNodes {

    /// Enumerates all of the "Paragraph ElementNode's" contained within a collection of AttributedString's Atributes.
    ///
    func enumerateParagraphNodes(in style: ParagraphStyle, block: ((ElementNode) -> Void)) {
        for property in style.properties.reversed() {
            switch property {
            case let blockquote as Blockquote:
                processBlockquoteStyle(blockquote: blockquote, block: block)

            case let header as Header:
                processHeaderStyle(header: header, block: block)

            case let list as TextList:
                processListStyle(list: list, block: block)

            case let paragraph as HTMLParagraph:
                processParagraphStyle(paragraph: paragraph, block: block)

            default:
                continue
            }
        }
    }


    ///
    ///
    private func processBlockquoteStyle(blockquote: Blockquote, block: ((ElementNode) -> Void)) {
        let node = blockquote.representation?.toNode() ?? ElementNode(type: .blockquote)
        block(node)
    }


    ///
    ///
    private func processHeaderStyle(header: Header, block: ((ElementNode) -> Void)) {
        guard let type = ElementNode.elementTypeForHeaderLevel(header.level.rawValue) else {
            return
        }

        let node = header.representation?.toNode() ?? ElementNode(type: type)
        block(node)
    }


    ///
    ///
    private func processListStyle(list: TextList, block: ((ElementNode) -> Void)) {
        let elementType = list.style == .ordered ? StandardElementType.ol : StandardElementType.ul
        let listElement = list.representation?.toNode() ?? ElementNode(type: elementType)
        let itemElement = ElementNode(type: .li)

        // TODO: LI needs it's Original Attributes!!
        block(itemElement)
        block(listElement)
    }


    ///
    ///
    private func processParagraphStyle(paragraph: HTMLParagraph, block: ((ElementNode) -> Void)) {
        let node = paragraph.representation?.toNode() ?? ElementNode(type: .p)
        block(node)
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


    ///
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


    ///
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


    ///
    ///
    private func processStrikethruStyle(in attributes: [String: Any]) -> [ElementNode] {
        guard attributes[NSStrikethroughStyleAttributeName] != nil else {
            return []
        }

        let representation = attributes[StrikethroughFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .strike)

        return [node]
    }


    ///
    ///
    private func processUnderlineStyle(in attributes: [String: Any]) -> [ElementNode] {
        guard attributes[NSUnderlineStyleAttributeName] != nil else {
            return []
        }

        let representation = attributes[UnderlineFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .u)

        return [node]
    }


    ///
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

        return [node]
    }


    /// Converts a String into it's representing nodes.
    ///
    private func processTextNodes(from text: String) -> [Node] {
        let substrings = text.components(separatedBy: String(.newline))
        var output = [Node]()

        for substring in substrings {
            if output.count > 0 {
                let newline = ElementNode(type: .br)
                output.append(newline)
            }

            let node = TextNode(text: substring)
            output.append(node)
        }

        return output
    }


    ///
    ///
    private func videoSourceAttribute(from attachment: VideoAttachment) -> StringAttribute? {
        guard let source = attachment.srcURL?.absoluteString else {
            return nil
        }

        return StringAttribute(name: "src", value: source)
    }


    ///
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
