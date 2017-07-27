import Foundation
import libxml2

class InNodeConverter: SafeConverter {
    
    /// Converts a single node (from libxml2) into an HTML.Node.
    ///
    /// - Parameters:
    ///     - attributes: the libxml2 attribute to convert.
    ///
    /// - Returns: an HTML.Node.
    ///
    func convert(_ rawNode: xmlNode) -> Node {
        var node: Node

        switch rawNode.type {
        case XML_TEXT_NODE:
            node = createTextNode(rawNode)
        case XML_COMMENT_NODE:
            node = createCommentNode(rawNode)
        default:
            node = createElementNode(rawNode)
        }

        return node
    }

    fileprivate func createAttributes(fromNode rawNode: xmlNode) -> [Attribute] {
        let attributesConverter = InAttributesConverter()
        return attributesConverter.convert(rawNode.properties)
    }

    /// Creates an HTML.Node from a libxml2 element node.
    ///
    /// - Parameters:
    ///     - rawNode: the libxml2 xmlNode.
    ///
    /// - Returns: the HTML.ElementNode
    ///
    fileprivate func createElementNode(_ rawNode: xmlNode) -> ElementNode {

        let nodeName = getNodeName(rawNode)

        switch nodeName.lowercased() {
        case RootNode.name:
            return createRootNode(rawNode)
        default:
            break
        }

        var children = [Node]()

        if rawNode.children != nil {
            let nodesConverter = InNodesConverter()
            children.append(contentsOf: nodesConverter.convert(rawNode.children))
        }

        let attributes = createAttributes(fromNode: rawNode)
        let node = ElementNode(name: nodeName, attributes: attributes, children: children)

        // TODO: This can be optimized to be set during instantiation of the child nodes.
        //
        for child in children {
            child.parent = node
        }

        return node
    }

    /// Creates an HTML.RootNode from a libxml2 element root node.
    ///
    /// - Parameters:
    ///     - rawNode: the libxml2 xmlNode.
    ///
    /// - Returns: the HTML.RootNode
    ///
    fileprivate func createRootNode(_ rawNode: xmlNode) -> RootNode {
        var children = [Node]()

        if rawNode.children != nil {
            let nodesConverter = InNodesConverter()
            children.append(contentsOf: nodesConverter.convert(rawNode.children))
        }

        let node = RootNode(children: children)

        // TODO: This can be optimized to be set during instantiation of the child nodes.
        //
        for child in children {
            child.parent = node
        }
        
        return node
    }

    func hasNode(_ rawNode: xmlNode, ancestorOfType type: StandardElementType) -> Bool {
        var parentNode = rawNode.parent
        while parentNode != nil {
            guard let xmlNode = parentNode?.pointee else {
                return true
            }
            if xmlNode.name != nil && String(cString:xmlNode.name) == type.rawValue {
                return false
            }
            parentNode = xmlNode.parent
        }
        return true
    }

    /// This method check that in the current context it makes sense to clean up newlines and double spaces from text.
    /// For example if you are inside a pre element you shoulnd't clean up the nodes.
    ///
    /// - Parameter rawNode: the base node to check
    ///
    /// - Returns: true if sanitization should happen, false otherwise
    func shouldSanitizeText(inNode rawNode: xmlNode) -> Bool {
        return hasNode(rawNode, ancestorOfType: .pre)
    }

    /// Creates an HTML.TextNode from a libxml2 element node.
    ///
    /// - Parameters:
    ///     - rawNode: the libxml2 xmlNode.
    ///
    /// - Returns: the HTML.TextNode
    ///
    fileprivate func createTextNode(_ rawNode: xmlNode) -> TextNode {
        var text = String(cString: rawNode.content)
        if shouldSanitizeText(inNode: rawNode) {
            text = sanitize(text)
        }
        let node = TextNode(text: text)

        return node
    }

    /// Creates an HTML.CommentNode from a libxml2 element node.
    ///
    /// - Parameters:
    ///     - rawNode: the libxml2 xmlNode.
    ///
    /// - Returns: the HTML.CommentNode
    ///
    fileprivate func createCommentNode(_ rawNode: xmlNode) -> CommentNode {
        let text = String(cString: rawNode.content)
        let node = CommentNode(text: text)

        return node
    }

    fileprivate func getNodeName(_ rawNode: xmlNode) -> String {
        return String(cString: rawNode.name)
    }

    // MARK: - Sanitization

    private func sanitize(_ text: String) -> String {

        let hasAnEndingSpace = text.hasSuffix(String(.space))
        let hasAStartingSpace = text.hasPrefix(String(.space))

        // We cannot use CharacterSet.whitespacesAndNewlines directly, because it includes
        // U+000A, which is non-breaking space.  We need to maintain it.
        //
        let whitespace = CharacterSet.whitespacesAndNewlines
        let whitespaceToKeep = CharacterSet(charactersIn: String(.nonBreakingSpace))
        let whitespaceToRemove = whitespace.subtracting(whitespaceToKeep)

        let trimmedText = text.trimmingCharacters(in: whitespaceToRemove)
        var singleSpaceText = trimmedText
        let doubleSpace = "  "
        let singleSpace = " "

        while singleSpaceText.range(of: doubleSpace) != nil {
            singleSpaceText = singleSpaceText.replacingOccurrences(of: doubleSpace, with: singleSpace)
        }

        let noBreaksText = singleSpaceText.replacingOccurrences(of: String(.lineFeed), with: "")
        let endingSpace = !noBreaksText.isEmpty && hasAnEndingSpace ? String(.space) : ""
        let startingSpace = !noBreaksText.isEmpty && hasAStartingSpace ? String(.space) : ""
        return "\(startingSpace)\(noBreaksText)\(endingSpace)"
    }
}

