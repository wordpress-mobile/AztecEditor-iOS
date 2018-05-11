import Aztec
import Foundation

public extension Element {
    static let gutenblock = Element("gutenblock")
}

public class GutenbergOutputHTMLTreeProcessor: HTMLTreeProcessor {
    
    public func process(_ rootNode: RootNode) {
        
        // We're enumerating in reverse, since this loop can replace the current node with
        // 1..N nodes.
        for (index, node) in rootNode.children.reversed().enumerated() {
            guard let element = gutenblockElement(from: node),
                let gutenblock = gutenblock(from: element) else {
                    return
            }
            
            let openingComment = CommentNode(text: gutenblock)
            let containedNodes = element.children
            let closingComment = CommentNode(text: gutenblock)
            
            let replacementNodes = [openingComment] + containedNodes + [closingComment]
            
            rootNode.children.replaceSubrange(index...index, with: replacementNodes)
        }
    }
    
    // MARK: - Base64 Decoding
    
    private func decode(base64Gutenblock: String) -> String {
        let data = Data(base64Encoded: base64Gutenblock)!
        return String(data: data, encoding: .utf16)!
    }
    
    // MARK: - Retrieving the Gutenblock data.
    
    private func gutenblockElement(from node: Node) -> ElementNode? {
        guard node.name == Element.gutenblock.rawValue,
            let element = node as? ElementNode else {
                return nil
        }
        
        return element
    }
    
    private func gutenblock(from element: ElementNode) -> String? {
        guard let attribute = dataAttribute(from: element),
            let gutenblock = gutenblock(from: attribute) else {
                return nil
        }
        
        return gutenblock
    }
    
    private func dataAttribute(from element: ElementNode) -> Attribute? {
        return element.attributes.first { (attribute) -> Bool in
            return attribute.name == "data"
        }
    }
    
    private func gutenblock(from attribute: Attribute) -> String? {
        guard let base64Gutenblock = attribute.value.toString() else {
            return nil
        }
        
        return decode(base64Gutenblock: base64Gutenblock)
    }
}
