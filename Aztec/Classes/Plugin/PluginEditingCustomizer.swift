import Foundation

public protocol PluginEditingCustomizer {
    
    /// Whenever a new & empty paragraph is created, this method allows customization of the typing attributes.
    ///
    func typingAttributesForNewParagraph(previous previousAttributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any]
}

extension PluginEditingCustomizer {
    
    public func typingAttributesForNewParagraph(
        previous previousAttributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        
        return previousAttributes
    }
}
