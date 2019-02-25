import Foundation
import UIKit

public protocol PluginOutputCustomizer {
    
    /// Processes an HTML string right after converting it from a nodes tree in the output
    /// conversion process.
    ///
    func process(html: String) -> String
    
    /// Processes a nodes tree right before it'll bee converted to a string, and before finalizing
    /// the output conversion process.
    ///
    func process(htmlTree: RootNode)
    
    /// Converts a paragraph property into the ElementNode that represents it.
    ///
    func convert(_ paragraphProperty: ParagraphProperty) -> ElementNode?
    
    /// Converts an attachment into the `[Node]`s that represent it.
    ///
    func convert(_ attachment: NSTextAttachment, attributes: [NSAttributedString.Key: Any]) -> [Node]?
    
    func converter(for elementNode: ElementNode) -> ElementToTagConverter?
}

extension PluginOutputCustomizer {
    
    func process(html: String) -> String { return html }
    func process(htmlTree: RootNode) { return }
    func convert(_ paragraphProperty: ParagraphProperty) -> ElementNode? { return nil }
    func convert(_ attachment: NSTextAttachment, attributes: [NSAttributedString.Key: Any]) -> [Node]? { return nil }
    func converter(for elementNode: ElementNode) -> ElementToTagConverter? { return nil }
}
