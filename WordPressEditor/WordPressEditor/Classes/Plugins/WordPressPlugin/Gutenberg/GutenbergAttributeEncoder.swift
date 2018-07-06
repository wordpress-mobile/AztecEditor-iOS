import Foundation
import Aztec

/// Class to facilitate encoding of Gutenberg comments data from Element attributes
///
class GutenbergAttributeEncoder {
    
    // MARK: - Encoding Comment Nodes
    
    func closerAttribute(for commentNode: CommentNode) -> Attribute {
        return attribute(.blockCloser, withValue: commentNode.comment)
    }
    
    func openerAttribute(for commentNode: CommentNode) -> Attribute {
        return attribute(.blockOpener, withValue: commentNode.comment)
    }
    
    func selfClosingAttribute(for commentNode: CommentNode) -> Attribute {
        return attribute(.selfCloser, withValue: commentNode.comment)
    }
    
    // MARK: - Encoding Strings
    
    func closerAttribute(_ text: String) -> Attribute {
        return attribute(.blockCloser, withValue: text)
    }
    
    func openerAttribute(_ text: String) -> Attribute {
        return attribute(.blockOpener, withValue: text)
    }
    
    func selfClosingAttribute(_ text: String) -> Attribute {
        return attribute(.selfCloser, withValue: text)
    }
    
    // MARK: - Encoding

    private func attribute(_ attribute: GutenbergAttribute, withValue text: String) -> Attribute {
        let base64String = encode(text)
        
        return Attribute(name: attribute, value: .string(base64String))
    }
    
    // MARK: - Base64 Encoding
    
    private func encode(_ string: String) -> String {
        let data = string.data(using: .utf16)!
        let base64String = data.base64EncodedString()
        
        return base64String
    }
}
