import Foundation

open class Plugin {
    
    public init() {}
    
    public func loaded(into textView: TextView) {}
    
    open func process(inputHTML html: String) -> String { return html }
    open func process(outputHTML html: String) -> String { return html }

    open func getInputHTMLTreeProcessor() -> HTMLTreeProcessor? { return nil }
    open func getOutputHTMLTreeProcessor() -> HTMLTreeProcessor? { return nil }
    open func getElementConverter() -> ElementConverter? { return nil }

    public static func ==(lhs: Plugin, rhs: Plugin) -> Bool {
        return type(of: lhs) == type(of: rhs)
    }
}

extension Array where Element: Plugin {
    
    func process(inputHTML html: String) -> String {
        return reduce(html) { (html, plugin) -> String in
            plugin.process(inputHTML: html)
        }
    }
    
    func process(outputHTML html: String) -> String {
        return reduce(html) { (html, plugin) -> String in
            plugin.process(outputHTML: html)
        }
    }
    
    func process(inputHTMLTree tree: RootNode) {
        for plugin in self {
            plugin.getInputHTMLTreeProcessor()?.process(tree)
        }
    }
    
    func process(outputHTMLTree tree: RootNode) {
        for plugin in self {
            plugin.getOutputHTMLTreeProcessor()?.process(tree)
        }
    }
}
