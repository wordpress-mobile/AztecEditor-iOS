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
        var previous = [Node]()

        attrString.enumerateParagraphRanges(spanning: attrString.rangeOfEntireString) { (paragraphRange, _) in
            let paragraph = attrString.attributedSubstring(from: paragraphRange)
            let children = createNodes(fromParagraph: paragraph)

            let left = rightmostParagraphStyleElements(from: previous)
            let right = leftmostParagraphStyleElements(from: children)

            guard !merge(left: left, right: right) else {
                return
            }

            if !previous.isEmpty && left.count == 0 && right.count == 0 {
                nodes += [ ElementNode(type: .br) ]
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
            let nodes = createStyleNodes(from: attrs, leaves: leaves)

            children.append(contentsOf: nodes)
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


    /// Extracts all of the Style Nodes contained within a collection of AttributedString Attributes.
    ///
    /// - Parameters:
    ///     - attrs: Collection of attributes that should be converted.
    ///     - leaves: Leaf nodes that should be used to regen the tree.
    ///
    /// - Returns: Style Nodes contained within the specified collection of attributes
    ///
    func createStyleNodes(from attrs: [String: Any], leaves: [Node]) -> [Node] {
        var lastNodes: [ElementNode]?

        enumerateStyleNodes(in: attrs) { node in
            node.children = lastNodes ?? leaves
            lastNodes = [node]
        }

        return lastNodes ?? leaves
    }


    /// Extract all of the Leaf Nodes contained within an Attributed String. We consider the following as Leaf:
    /// Plain Text, Attachments of any kind [Line, Comment, HTML, Image].
    ///
    /// - Parameter attrString: AttributedString that should be converted.
    ///
    /// - Returns: Leaf Nodes contained within the specified collection of attributes
    ///
    func createLeafNodes(from attrString: NSAttributedString) -> [Node] {
        let attachment = attrString.attribute(NSAttachmentAttributeName, at: 0, effectiveRange: nil) as? NSTextAttachment

        switch attachment {
        case let lineAttachment as LineAttachment:
            return lineAttachmentToNodes(lineAttachment)
        case let commentAttachment as CommentAttachment:
            return commentAttachmentToNodes(commentAttachment)
        case let htmlAttachment as HTMLAttachment:
            return htmlAttachmentToNode(htmlAttachment)
        case let imageAttachment as ImageAttachment:
            return imageAttachmentToNodes(imageAttachment)
        case let videoAttachment as VideoAttachment:
            return videoAttachmentToNodes(videoAttachment)
        default:
            return textToNodes(attrString.string)
        }
    }
}


// MARK: - Enumerators
//
private extension NSAttributedStringToNodes {

    /// Enumerates all of the "Paragraph ElementNode's" contained within a collection of AttributedString's Atributes.
    ///
    func enumerateParagraphNodes(in style: ParagraphStyle, block: ((ElementNode) -> Void)) {
        for property in style.properties.reversed() {
            switch property {
            case is Blockquote:
                block( ElementNode(type: .blockquote) )

            case let header as Header:
                guard let type = ElementNode.elementTypeForHeaderLevel(header.level.rawValue) else {
                    continue
                }

                block( ElementNode(type: type) )

            case let list as TextList:
                let textListElement = list.style == .ordered ? ElementNode(type: .ol) : ElementNode(type: .ul)

                block( ElementNode(type: .li) )
                block( textListElement )

            case is HTMLParagraph:
                block( ElementNode(type: .p) )

            default:
                continue
            }
        }
    }


    /// Enumerates all of the "Style ElementNode's" contained within a collection of AttributedString's Atributes.
    ///
    func enumerateStyleNodes(in attributes: [String: Any], block: ((ElementNode) -> Void)) {
        processFontStyle(in: attributes, block: block)
        processLinkStyle(in: attributes, block: block)
        processStrikethruStyle(in: attributes, block: block)
        processUnderlineStyle(in: attributes, block: block)
        processUnsupportedHTML(in: attributes, block: block)
    }


    ///
    ///
    private func processFontStyle(in attributes: [String: Any], block: ((ElementNode) -> Void)) {
        guard let font = attributes[NSFontAttributeName] as? UIFont else {
            return
        }

        if font.containsTraits(.traitBold) {
            let representation = attributes[BoldFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
            let node = representation?.toNode() ?? ElementNode(type: .b)

            block(node)
        }

        if font.containsTraits(.traitItalic) {
            let representation = attributes[ItalicFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
            let node = representation?.toNode() ?? ElementNode(type: .i)

            block(node)
        }
    }


    ///
    ///
    private func processLinkStyle(in attributes: [String: Any], block: ((ElementNode) -> Void)) {
        guard let url = attributes[NSLinkAttributeName] as? URL else {
            return
        }

        let representation = attributes[LinkFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .a)
        node.updateAttribute(named: "href", value: url.absoluteString)

        block(node)
    }


    ///
    ///
    private func processStrikethruStyle(in attributes: [String: Any], block: ((ElementNode) -> Void)) {
        guard attributes[NSStrikethroughStyleAttributeName] != nil else {
            return
        }

        let representation = attributes[StrikethroughFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .strike)

        block(node)
    }


    ///
    ///
    private func processUnderlineStyle(in attributes: [String: Any], block: ((ElementNode) -> Void)) {
        guard attributes[NSUnderlineStyleAttributeName] != nil else {
            return
        }

        let representation = attributes[UnderlineFormatter.htmlRepresentationKey] as? HTMLElementRepresentation
        let node = representation?.toNode() ?? ElementNode(type: .u)

        block(node)
    }


    ///
    ///
    private func processUnsupportedHTML(in attributes: [String: Any], block: ((ElementNode) -> Void)) {
        guard let unsupported = attributes[UnsupportedHTMLAttributeName] as? UnsupportedHTML else {
            return
        }

        for element in unsupported.elements.reversed() {
            block(element.toNode())
        }
    }
}


// MARK: - Leaf Nodes
//
private extension NSAttributedStringToNodes {

    /// Converts a Line Attachment into it's representing nodes.
    ///
    func lineAttachmentToNodes(_ lineAttachment: LineAttachment) -> [Node] {
        let node = ElementNode(type: .hr)
        return [node]
    }


    /// Converts a Comment Attachment into it's representing nodes.
    ///
    func commentAttachmentToNodes(_ attachment: CommentAttachment) -> [Node] {
        let node = CommentNode(text: attachment.text)
        return [node]
    }


    /// Converts an HTML Attachment into it's representing nodes.
    ///
    func htmlAttachmentToNode(_ attachment: HTMLAttachment) -> [Node] {
        let converter = Libxml2.In.HTMLConverter()

        let rootNode = converter.convert(attachment.rawHTML)

        guard let firstChild = rootNode.children.first else {
            return textToNodes(attachment.rawHTML)
        }

        guard rootNode.children.count == 1 else {
            let node = ElementNode(type: .span, attributes: [], children: rootNode.children)
            return [node]
        }

        return [firstChild]
    }


    /// Converts an Image Attachment into it's representing nodes.
    ///
    func imageAttachmentToNodes(_ attachment: ImageAttachment) -> [Node] {
        var attributes = [Attribute]()
        if let attribute = imageSourceAttribute(from: attachment) {
            attributes.append(attribute)
        }

        if let attribute = imageClassAttribute(from: attachment) {
            attributes.append(attribute)
        }

        let node = ElementNode(type: .img, attributes: attributes)
        return [node]
    }

    /// Converts an Video Attachment into it's representing nodes.
    ///
    func videoAttachmentToNodes(_ attachment: VideoAttachment) -> [Node] {
        var attributes = [Attribute]()
        if let source = attachment.srcURL?.absoluteString {
            let attribute = StringAttribute(name: "src", value: source)
            attributes.append(attribute)
        }

        if let poster = attachment.posterURL?.absoluteString {
            let attribute = StringAttribute(name: "poster", value: poster)
            attributes.append(attribute)
        }

        let node = ElementNode(type: .video, attributes: attributes)
        return [node]
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


    /// Converts a String into it's representing nodes.
    ///
    func textToNodes(_ text: String) -> [Node] {
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
}
