import Foundation

/// Plugin base class.  You can implement a subclass to customize some of the behavior in Aztec.
///
open class Plugin {
    
    public init() {}
    
    public func loaded() {}
    
    open func process(inputHTML html: String) -> String { return html }
    open func process(outputHTML html: String) -> String { return html }
    open func process(inputHTMLTree tree: RootNode) { return }
    open func process(outputHTMLTree tree: RootNode) { return }
    
    open func elementConverters() -> [ElementConverter] { return [] }

    public static func ==(lhs: Plugin, rhs: Plugin) -> Bool {
        return type(of: lhs) == type(of: rhs)
    }
}
