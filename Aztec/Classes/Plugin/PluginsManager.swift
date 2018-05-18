import Foundation

class PluginsManager {
    
    // MARK: - Plugin Loading
    
    private(set) var plugins = [Plugin]()
    
    public func load(_ plugin: Plugin) {
        guard !plugins.contains(where: { $0 == plugin }) else {
            assertionFailure()
            return
        }
        
        plugins.append(plugin)
        plugin.loaded()
    }
    
    // MARK: - Processing
    
    func process(inputHTML html: String) -> String {
        return plugins.reduce(html) { (html, plugin) -> String in
            plugin.process(inputHTML: html)
        }
    }
    
    func process(outputHTML html: String) -> String {
        return plugins.reduce(html) { (html, plugin) -> String in
            plugin.process(outputHTML: html)
        }
    }
    
    func process(inputHTMLTree tree: RootNode) {
        for plugin in plugins {
            plugin.process(inputHTMLTree: tree)
        }
    }
    
    func process(outputHTMLTree tree: RootNode) {
        for plugin in plugins {
            plugin.process(outputHTMLTree: tree)
        }
    }
}

