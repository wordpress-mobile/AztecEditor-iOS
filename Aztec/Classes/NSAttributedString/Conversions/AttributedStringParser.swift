import Foundation
import UIKit
import libxml2

/// This protocol can be implemented by an object that wants to modify the behavior
/// of the AttributedStringParser.
///
protocol AttributedStringParserCustomizer: ParagraphPropertyConverter, BaseAttachmentToElementConverter {}

/// Parses an attributed string into an HTML tree.
///
class AttributedStringParser {
    
    // MARK: - Plugin Manager
    
    let customizer: AttributedStringParserCustomizer?
    
    // MARK: - Initializers
    
    init(customizer: AttributedStringParserCustomizer? = nil) {
        self.customizer = customizer
    }
    
    // MARK: - String Attribute Converters
    
    private let stringAttributeConverters: [StringAttributeConverter] = [
        BoldStringAttributeConverter(),
        ConditionalItalicStringAttributeConverter(),
        UnderlineStringAttributeConverter(),
    ]
    
    // MARK: - Attachment Converters
    
    private let attachmentConverters: [BaseAttachmentToElementConverter] = [
        CommentAttachmentToElementConverter(),
        HTMLAttachmentToElementConverter(),
        ImageAttachmentToElementConverter(),
        LineAttachmentToElementConverter(),
        VideoAttachmentToElementConverter(),
    ]
    
    // MARK: - Internal Data Structures
    
    private struct ParagraphPropertyConversion {
        let property: ParagraphProperty
        let elementNode: ElementNode
        let preformatted: Bool
    }
    
    // MARK: - Parsing

    /// Parses an attributed string and returns the corresponding HTML tree.
    ///
    /// - Parameters:
    ///     - attrString: the attributed string to parse
    ///
    /// - Returns: the HTML tree.
    ///
    func parse(_ attrString: NSAttributedString) -> RootNode {
        var nodes = [Node]()
        var previousParagraphConversions = [ParagraphPropertyConversion]()
        
        /// This internal mini-method just "submits" the previous conversions.
        /// It appends the root element from that conversion into the result.
        func submitPreviousConversions() {
            if let firstConversion = previousParagraphConversions.first {
                nodes.append(firstConversion.elementNode)
            }
        }

        attrString.enumerateParagraphRanges(spanning: attrString.rangeOfEntireString) { (paragraphRange, enclosingRange) in
            
            let attributes = attrString.attributes(at: paragraphRange.location, effectiveRange: nil)
            let paragraphStyle = attributes.paragraphStyle()
            let styleNodes = createNodes(from: attrString, paragraphRange: paragraphRange, enclosingRange: enclosingRange)
            
            if let mergedConversions = merge(paragraphStyle.properties, into: previousParagraphConversions, styleNodes: styleNodes) {
                previousParagraphConversions = mergedConversions
            } else {
                submitPreviousConversions()
                
                previousParagraphConversions = convert(ArraySlice(paragraphStyle.properties), styleNodes: styleNodes)
            }
        }
        
        submitPreviousConversions()

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

        return process(branches: branches)
    }


    /// Converts a collection of Attributes into their Node(s) representation.
    ///
    /// - Parameter attributes: Attributes to be mapped into nodes
    ///
    /// - Returns: Array of Node instances.
    ///
    private func createNodes(from attributes: [NSAttributedString.Key: Any]) -> [Node] {
        let nodes = createStyleNodes(from: attributes)

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
    private struct MergeablePair {
        let left: ElementNode
        let right: ElementNode
        let preformatted: Bool
    }


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
    private func findMergeableNodes(left leftElements: [ElementNode], right rightElements: [ElementNode], blocklevelEnforced: Bool = true) -> [MergeablePair]? {
        var currentIndex = 0
        var matching = [MergeablePair]()
        var preformatted = false

        while currentIndex < leftElements.count && currentIndex < rightElements.count {
            let left = leftElements[currentIndex]
            let right = rightElements[currentIndex]

            guard canMergeNodes(left:left, right: right, blocklevelEnforced: blocklevelEnforced) else {
                break
            }
            
            if left.type == .pre {
                // Once we find a `<pre>` node, all children become preformatted.
                preformatted = true
            }

            let pair = MergeablePair(left: left, right: right, preformatted: preformatted)
            matching.append(pair)
            currentIndex += 1
        }

        return matching.isEmpty ? nil : matching
    }

    /// Indicates whether the children of the specified node can be merged in, or not.
    ///
    /// - Parameters:
    ///     - node: Target node for which we'll determine Merge-ability status.
    ///
    /// - Returns: true if both nodes can be merged, or not.
    ///
    func canMergeNodes(left: ElementNode, right: ElementNode, blocklevelEnforced: Bool) -> Bool {
        guard left.name == right.name && Set(left.attributes) == Set(right.attributes) else {
            return false
        }

        guard blocklevelEnforced else {
            return Element.mergeableStyleElements.contains(left.type)
        }

        return Element.mergeableBlockLevelElements.contains(left.type)
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

        let mergeableLeftNodes = mergeableCandidate.compactMap { $0.left }
        let mergeableRightNodes = mergeableCandidate.compactMap { $0.right }

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
    
    /// Tries to merge an array of properties with the (property -> elementNode) conversions form the previous paragraph.
    ///
    /// - Parameters:
    ///     - newProperties: the properties from the paragraph being converted.
    ///     - previousConversions: the conversions used for the previous paragraph.
    ///     - styleNodes: the style nodes.
    ///
    /// -Returns: `nil` if no previous conversion can be re-used.
    ///
    private func merge(
        _ newProperties: [ParagraphProperty],
        into previousConversions: [ParagraphPropertyConversion],
        styleNodes: [Node]) -> [ParagraphPropertyConversion]? {
        
        guard let mergeableConversions = self.mergeableConversions(from: previousConversions, for: newProperties),
            let lastMergeableConversion = mergeableConversions.last else {
                return nil
        }
        
        let lastMergeableElementNode = lastMergeableConversion.elementNode
        let somePropertiesAreNotMergeable = newProperties.count > mergeableConversions.count
        
        guard somePropertiesAreNotMergeable else {
            // At this point we gotta check if we can merge the last style element from the left with the first style element from the right.
            if let previousStyleNode = lastMergeableConversion.elementNode.children.last as? ElementNode,
                let styleNode = styleNodes.first as? ElementNode,
                canMergeNodes(left: previousStyleNode, right: styleNode, blocklevelEnforced: false) {
                
                let children = lastMergeableConversion.preformatted ? prependParagraphSeparatorTextNode(to: styleNode.children) : styleNode.children
                
                previousStyleNode.children.append(contentsOf: children)
                
                if styleNodes.count > 1 {
                    append(styleNodes[1 ..< styleNodes.endIndex], to: mergeableConversions)
                }
            } else {
                // If all properties are merged and the last mergeable conversion is preformatted, we should prepend the
                // styleNodes with a paragraph separator text node.
                let finalStyleNodes = lastMergeableConversion.preformatted ? prependParagraphSeparatorTextNode(to: styleNodes) : styleNodes
                
                append(finalStyleNodes[0 ..< finalStyleNodes.endIndex], to: mergeableConversions)
            }
            
            return Array(mergeableConversions)
        }
        
        let firstUnmergedIndex = mergeableConversions.count
        let unmergedSlice = newProperties[firstUnmergedIndex ..< newProperties.count]
        let unmergeableConversions = convert(unmergedSlice, styleNodes: styleNodes)
        
        // This isn't very evident immediately, but what this does it connect the mergeable and unmergeable conversion elements.
        if let firstUnmergeableElementNode = unmergeableConversions.first?.elementNode {
            lastMergeableElementNode.children.append(firstUnmergeableElementNode)
        }
        
        return mergeableConversions + unmergeableConversions
    }
    
    /// Calculates which previous conversions can be merged for the new properties.
    ///
    private func mergeableConversions(from previousConversions: [ParagraphPropertyConversion], for newProperties: [ParagraphProperty]) -> ArraySlice<ParagraphPropertyConversion>? {
        
        var lastMergeableIndex = -1
        
        for (index, conversion) in previousConversions.enumerated() {
            guard newProperties.count > index else {
                break
            }

            guard isMergable(conversion, with: newProperties, at: index) else {
                break
            }
            
            lastMergeableIndex = index
        }

        guard lastMergeableIndex >= 0 else {
            return nil
        }
        
        let mergeableCount = lastMergeableIndex + 1
        
        // There are certain scenarios in which the last block-level element that's mergeable has to remain unmerged.
        //
        // The first way to represent a newline (a paragraph interruption) in HTML is by interrupting the "lowest" / "last"
        // block-level element in a tree.
        //
        // As an alternative, preformatted blocks don't need to be broken because they respect their whitespace.  This means
        // that a regular newline character is enough to break the paragraph.
        //
        let canKeepLastConversion =
            mergeableCount < previousConversions.count // If the previous conversions have a block-level child, we can avoid breaking
                || mergeableCount < newProperties.count // If the current conversions have a block-level child, we can avoid breaking
                || previousConversions[lastMergeableIndex].preformatted // Preformatted blocks can be broken by a regular newline character
        
        if !canKeepLastConversion {
            guard lastMergeableIndex > 0 else {
                return nil
            }
            
            lastMergeableIndex -= 1
        }
        
        return previousConversions.prefix(through: lastMergeableIndex)
    }

    private func isMergable(_ conversion: ParagraphPropertyConversion, with newProperties: [ParagraphProperty], at index: Int) -> Bool {
        let previousProperty = conversion.property
        let newProperty = newProperties[index]

        // `li` tags as a rule will never merge, unless it has a `figure` or a `textlist` as child. We want to keep all
        // `figure` and textlist` children merged inside a single `li` tag.
        if newProperty is HTMLLi, newProperties.indices.contains(index + 1),
            newProperties[index + 1] is Figure ||  newProperties[index + 1] is TextList {
            return newProperty === previousProperty
        } else {
            return newProperty.isEqual(previousProperty)
        }
    }
}


// MARK: - Paragraph Properties Conversion
//
extension AttributedStringParser {
    
    /// Appends the provided nodes to the last element in a list of conversions.
    /// Used mainly for adding sub-paragraph style nodes.
    ///
    /// - Parameters:
    ///     - nodes: the nodes to append
    ///     - conversions: the conversions to append the nodes to.
    ///
    private func append(
        _ nodes: ArraySlice<Node>,
        to conversions: ArraySlice<ParagraphPropertyConversion>) {
        
        precondition(conversions.count > 0)
        
        let lastConversion = conversions.last!
        
        lastConversion.elementNode.children += nodes
    }
    
    /// Prepends a paragraph separator text node before the provided nodes.
    ///
    /// - Parameters:
    ///     - nodes: the nodes to prepend the paragraph separator to.
    ///
    /// - Returns: the nodes prepended with the requested paragraph separator text node.
    ///
    private func prependParagraphSeparatorTextNode(to nodes: [Node]) -> [Node] {
        let paragraphSeparator = TextNode(text: String(.paragraphSeparator))
        
        return [paragraphSeparator] + nodes
    }
    
    /// Provides the default paragraph property conversion.
    ///
    /// - Parameters:
    ///     - styleNodes: the style nodes to add to the current-paragraph conversions.
    ///
    /// - Returns: the default paragraph property conversion.
    ///
    private func defaultParagraphPropertyConversion(styleNodes: [Node]) -> ParagraphPropertyConversion {
        let defaultElement = ElementNode(type: .p, attributes: [], children: styleNodes)
        
        return ParagraphPropertyConversion(property: HTMLParagraph(with: nil), elementNode: defaultElement, preformatted: false)
    }
    
    /// Converts paragraph properties
    ///
    /// - Parameters:
    ///     - properties: the properties to convert.
    ///     - styleNodes: the style nodes.
    ///
    /// - Returns: the conversions for the provided properties.
    ///
    private func convert(_ properties: ArraySlice<ParagraphProperty>, styleNodes: [Node]) -> [ParagraphPropertyConversion] {
        var preformatted = false
        var parentElementNode: ElementNode?
        
        let conversions = properties.compactMap({ (property) -> ParagraphPropertyConversion? in
            guard let conversion = convert(property, preformatted: &preformatted) else {
                return nil
            }
            
            if let previousParentElementNode = parentElementNode {
                previousParentElementNode.children.append(conversion.elementNode)
            }
            
            parentElementNode = conversion.elementNode
            
            return conversion
        })
        
        // We don't allow not having at least 1 block-level element.
        guard conversions.count > 0 else {
            return [defaultParagraphPropertyConversion(styleNodes: styleNodes)]
        }
        
        append(styleNodes[0 ..< styleNodes.endIndex], to: ArraySlice(conversions))
        return conversions
    }
    
    /// Converts a paragraph property.
    ///
    /// - Parameters:
    ///     - property: the property to convert.
    ///     - preformatted: whether the property is preformatted, or a child of a preformatted property.
    ///
    /// - Returns: the conversion.
    ///
    private func convert(_ property: ParagraphProperty, preformatted: inout Bool) -> ParagraphPropertyConversion? {
        guard let elementNode = convert(property) else {
            return nil
        }
        
        preformatted = Element.preformattedElements.contains(elementNode.type)
        
        return ParagraphPropertyConversion(property: property, elementNode: elementNode, preformatted: preformatted)
    }
    
    /// Converts a paragraph property into an `ElementNode`.
    ///
    /// - Parameters:
    ///     - property: the property to convert.
    ///
    /// - Returns: an `ElementNode` to represent the property.
    ///
    private func convert(_ property: ParagraphProperty) -> ElementNode? {
        // The customizer overrides any default behaviour, which is the reason why it's run first.
        if let element = customizer?.convert(property) {
            return element
        }
        
        switch property {
        case let blockquote as Blockquote:
            let element = processBlockquoteStyle(blockquote: blockquote)
            return element
            
        case let figcaption as Figcaption:
            let element = processFigcaptionStyle(figcaption: figcaption)
            return element
            
        case let figure as Figure:
            let element = processFigureStyle(figure: figure)
            return element
            
        case let header as Header:
            guard let element = processHeaderStyle(header: header) else {
                return nil
            }
            return element
            
        case let list as TextList:
            let element = processListStyle(list: list)
            return element
            
        case let listItem as HTMLLi:
            let element = processListItem(listItem: listItem)
            return element
            
        case let div as HTMLDiv:
            let element = processDivStyle(div: div)
            return element
            
        case let paragraph as HTMLParagraph:
            let element = processParagraphStyle(paragraph: paragraph)
            return element
            
        case let pre as HTMLPre:
            let element = processPreStyle(pre: pre)
            return element
            
        default:
            return nil
        }
    }
}


// MARK: - Paragraph Nodes: Allocation
//
private extension AttributedStringParser {


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
    
    
    private func processFigcaptionStyle(figcaption: Figcaption) -> ElementNode {
        
        let element: ElementNode
        
        if let representation = figcaption.representation,
            case let .element(representationElement) = representation.kind {
            
            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .figcaption)
        }
        
        return element
    }
    
    
    private func processFigureStyle(figure: Figure) -> ElementNode {
        
        let element: ElementNode
        
        if let representation = figure.representation,
            case let .element(representationElement) = representation.kind {
            
            element = representationElement.toElementNode()
        } else {
            element = ElementNode(type: .figure)
        }
        
        return element
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
    private func processListStyle(list: TextList) -> ElementNode {
        let listType = list.style == .ordered ? Element.ol : Element.ul

        let listElement: ElementNode

        if let representation = list.representation,
            case let .element(element) = representation.kind {

            listElement = element.toElementNode()
        } else {
            listElement = ElementNode(type: listType)
        }

        return listElement
    }

    private func processListItem(listItem: HTMLLi) -> ElementNode {

        let lineElement: ElementNode

        if let representation = listItem.representation,
            case let .element(element) = representation.kind {

            lineElement = element.toElementNode()
        } else {
            lineElement = ElementNode(type: .li)
        }

        return lineElement
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
    func createStyleNodes(from attributes: [NSAttributedString.Key: Any]) -> [ElementNode] {
        var nodes = [ElementNode]()

        nodes += processUnsupportedHTML(in: attributes)
        
        for converter in stringAttributeConverters {
            nodes = converter.convert(attributes: attributes, andAggregateWith: nodes)
        }

        if let element = processLinkStyle(in: attributes) {
            nodes.append(element)
        }

        if let element = processStrikethruStyle(in: attributes) {
            nodes.append(element)
        }

        if let element = processCodeStyle(in: attributes) {
            nodes.append(element)
        }

        return nodes
    }

    /// Extracts all of the Link Elements contained within a collection of Attributes.
    ///
    private func processLinkStyle(in attributes: [NSAttributedString.Key: Any]) -> ElementNode? {
        var urlString = ""
        if let url = attributes[NSAttributedString.Key.link] as? URL {
            urlString = url.absoluteString
        } else if let link = attributes[NSAttributedString.Key.link] as? String {
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

        element.updateAttribute(ofType: .href, value: .string(urlString))

        return element
    }


    /// Extracts all of the Strike Elements contained within a collection of Attributes.
    ///
    private func processStrikethruStyle(in attributes: [NSAttributedString.Key: Any]) -> ElementNode? {
        guard attributes[NSAttributedString.Key.strikethroughStyle] != nil else {
            return nil
        }

        if let representation = attributes[NSAttributedString.Key.strikethroughHtmlRepresentation] as? HTMLRepresentation,
            case let .element(representationElement) = representation.kind {

            return representationElement.toElementNode()
        }

        return ElementNode(type: .s)
    }

    /// Extracts all of the Code Elements contained within a collection of Attributes.
    ///
    private func processCodeStyle(in attributes: [NSAttributedString.Key: Any]) -> ElementNode? {
        guard attributes[.codeHtmlRepresentation] is HTMLRepresentation else {
            return nil
        }

        return ElementNode(type: .code)
    }

    /// Extracts all of the Unsupported HTML Snippets contained within a collection of Attributes.
    ///
    private func processUnsupportedHTML(in attributes: [NSAttributedString.Key: Any]) -> [ElementNode] {
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
        
        if let attachment = attrString.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment {
            let attributes = attrString.attributes(at: 0, effectiveRange: nil)
            
            if let newNodes = customizer?.convert(attachment, attributes: attributes) {
                nodes += newNodes
            } else {
                for converter in attachmentConverters {
                    if let newNodes = converter.convert(attachment, attributes: attributes) {
                        nodes += newNodes
                        break
                    }
                }
            }
        }

        return nodes.isEmpty ? processTextNodes(from: attrString.string) : nodes
    }

    /// Converts a String into it's representing nodes.
    ///
    private func processTextNodes(from text: String) -> [Node] {
        let substrings = text.components(separatedBy: String(.lineSeparator))
        var output = [Node]()

        for (index, substring) in substrings.enumerated() {
            
            let cleanString = substring.replacingOccurrences(of: String(.zeroWidthSpace), with: "")
            output.append(TextNode(text: cleanString))

            if index < substrings.count - 1 {
                output.append(ElementNode(type: .br))
            }
        }
        
        return output
    }
}
