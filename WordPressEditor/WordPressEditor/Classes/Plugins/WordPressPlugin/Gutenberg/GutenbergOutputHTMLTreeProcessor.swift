import Aztec
import Foundation

public class GutenbergOutputHTMLTreeProcessor: HTMLTreeProcessor {
    
    public init() {}
    
    public func process(_ rootNode: RootNode) {
        
        rootNode.children = rootNode.children.flatMap({ (node) -> [Node] in
            guard let element = node as? ElementNode else {
                return [node]
            }
            
            if element.type == .gutenblock {
                let openingComment = gutenbergOpener(for: element)
                let containedNodes = element.children
                let closingComment = gutenbergCloser(for: element)
                let closingNewline = TextNode(text: "\n")
                
                return [openingComment] + containedNodes + [closingComment, closingNewline]
            } else if element.type == .gutenpack {
                let selfContainedBlockComment = gutenbergSelfCloser(for: element)
                
                return [selfContainedBlockComment]
            } else {
                return [element]
            }
        })
    }
}

// MARK: - Gutenberg Tags

private extension GutenbergOutputHTMLTreeProcessor {
    
    func gutenbergCloser(for element: ElementNode) -> CommentNode {
        guard let closer = gutenblockCloserData(for: element) else {
            fatalError("There's no scenario in which this information missing can make sense.  Review the logic.")
        }
        
        return CommentNode(text: closer)
    }
    
    func gutenbergOpener(for element: ElementNode) -> CommentNode {
        guard let opener = gutenblockOpenerData(for: element) else {
            fatalError("There's no scenario in which this information missing can make sense.  Review the logic.")
        }
    
        return CommentNode(text: opener)
    }
    
    func gutenbergSelfCloser(for element: ElementNode) -> CommentNode {
        guard let selfCloser = gutenblockSelfCloserData(for: element) else {
            fatalError("There's no scenario in which this information missing can make sense.  Review the logic.")
        }
        
        return CommentNode(text: selfCloser)
    }
    
    // MARK: - Gutenberg HTML Attribute Data
    
    private func gutenblockCloserData(for element: ElementNode) -> String? {
        return decodedAttribute(named: GutenbergAttributeNames.blockCloser, from: element)
    }
    
    private func gutenblockOpenerData(for element: ElementNode) -> String? {
        return decodedAttribute(named: GutenbergAttributeNames.blockOpener, from: element)
    }
    
    private func gutenblockSelfCloserData(for element: ElementNode) -> String? {
        return decodedAttribute(named: GutenbergAttributeNames.selfCloser, from: element)
    }
}

// MARK: - HTML Attributes

private extension GutenbergOutputHTMLTreeProcessor {

    // MARK: - Attribute Data
    
    private func attribute(named name: String, from element: ElementNode) -> Attribute? {
        return element.attributes.first { (attribute) -> Bool in
            return attribute.name == name
        }
    }
    
    func decodedAttribute(named name: String, from element: ElementNode) -> String? {
        guard let attribute = attribute(named: name, from: element),
            let opener = decode(attribute) else {
                return nil
        }
        
        return opener
    }
    
    // MARK: - Base64 Decoding
    
    private func decode(_ attribute: Attribute) -> String? {
        guard let base64Gutenblock = attribute.value.toString() else {
            return nil
        }
        
        return decode(base64Gutenblock: base64Gutenblock)
    }
    
    private func decode(base64Gutenblock: String) -> String {
        let data = Data(base64Encoded: base64Gutenblock)!
        return String(data: data, encoding: .utf16)!
    }
}
