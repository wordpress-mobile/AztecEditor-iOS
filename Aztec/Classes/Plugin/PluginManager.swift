import Foundation

/// This class managed the loading and provides an execution interface for plugins.
///
class PluginManager {
    
    // MARK: - Plugin Loading
    
    private(set) var plugins = [Plugin]()
    
    /// Loads a plugins.
    ///
    public func load(_ plugin: Plugin) {
        guard !plugins.contains(where: { $0 == plugin }) else {
            assertionFailure()
            return
        }
        
        plugins.append(plugin)
        plugin.loaded()
    }
    
    // MARK: - Input Processing
    
    /// Processes an HTML string right before parsing it to convert it into a nodes tree in
    /// the input conversion process.
    ///
    func process(inputHTML html: String) -> String {
        return plugins.reduce(html) { (html, plugin) -> String in
            plugin.process(inputHTML: html)
        }
    }
    
    /// Processes a nodes tree right after it's been parsed from a string, and before finalizing
    /// the input conversion process.
    ///
    func process(inputHTMLTree tree: RootNode) {
        for plugin in plugins {
            plugin.process(inputHTMLTree: tree)
        }
    }
    
    /// Creates the element converters map.  Uses a default map as the base, and updates it with
    /// the custom maps from all loaded plugins.
    ///
    /// - Important: when there are multiple mappings, the last plugin to load is the one that prevails.
    ///
    func inputElementConverters(with defaultElementConverters: [Element: ElementConverter]) -> [Element: ElementConverter] {
        var elementConverters = defaultElementConverters
        
        for plugin in plugins {
            elementConverters.merge(plugin.inputElementConverters()) { return $1 }
        }
        
        return elementConverters
    }
    
    // MARK: - Output Processing
    
    /// Processes an HTML string right after converting it from a nodes tree in the output
    /// conversion process.
    ///
    func process(outputHTML html: String) -> String {
        return plugins.reduce(html) { (html, plugin) -> String in
            plugin.process(outputHTML: html)
        }
    }
    
    /// Processes a nodes tree right before it'll bee converted to a string, and before finalizing
    /// the output conversion process.
    ///
    func process(outputHTMLTree tree: RootNode) {
        for plugin in plugins {
            plugin.process(outputHTMLTree: tree)
        }
    }
}

