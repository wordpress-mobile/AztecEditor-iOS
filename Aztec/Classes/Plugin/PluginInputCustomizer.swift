import Foundation

public protocol PluginInputCustomizer {
    
    /// Processes an HTML string right before parsing it to convert it into a nodes tree in
    /// the input conversion process.
    ///
    func process(html: String) -> String
    
    /// Processes a nodes tree right after it's been parsed from a string, and before finalizing
    /// the input conversion process.
    ///
    func process(htmlTree: RootNode)
    
    func converter(for elementNode: ElementNode) -> ElementConverter?
}

extension PluginInputCustomizer {

    func process(html: String) -> String { return html }
    func process(htmlTree: RootNode) { return }
    func converter(for elementNode: ElementNode) -> ElementConverter? { return nil }
}
