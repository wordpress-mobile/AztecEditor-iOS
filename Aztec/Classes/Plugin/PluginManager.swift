import Foundation

/// This class managed the loading and provides an execution interface for plugins.
///
class PluginManager {
    
    // MARK: - Plugin Loading
    
    private(set) var plugins = [Plugin]()
    
    /// Loads a plugins.
    ///
    func load(_ plugin: Plugin) {
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
            guard let customizer = plugin.inputCustomizer else {
                return html
            }
            
            return customizer.process(inputHTML: html)
        }
    }
    
    /// Processes a nodes tree right after it's been parsed from a string, and before finalizing
    /// the input conversion process.
    ///
    func process(inputHTMLTree tree: RootNode) {
        for plugin in plugins {
            if let customizer = plugin.inputCustomizer {
                customizer.process(inputHTMLTree: tree)
            }
        }
    }
    
    // MARK: - Output Processing
    
    /// Processes an HTML string right after converting it from a nodes tree in the output
    /// conversion process.
    ///
    func process(outputHTML html: String) -> String {
        return plugins.reduce(html) { (html, plugin) -> String in
            guard let customizer = plugin.outputCustomizer else {
                return html
            }
            
            return customizer.process(outputHTML: html)
        }
    }
    
    /// Processes a nodes tree right before it'll bee converted to a string, and before finalizing
    /// the output conversion process.
    ///
    func process(outputHTMLTree tree: RootNode) {
        for plugin in plugins {
            if let customizer = plugin.outputCustomizer {
                customizer.process(outputHTMLTree: tree)
            }
        }
    }
}

// MARK: - AttributedStringSerializerCustomizer

extension PluginManager: AttributedStringSerializerCustomizer {
    func converter(for element: ElementNode) -> ElementConverter? {
        for plugin in plugins {
            if let customizer = plugin.inputCustomizer,
                let converter = customizer.converter(for: element) {
                
                return converter
            }
        }
        
        return nil
    }
}

// MARK: - AttributedStringParserCustomizer

extension PluginManager: AttributedStringParserCustomizer {
    func convert(_ paragraphProperty: ParagraphProperty) -> ElementNode? {
        for plugin in plugins {
            if let customizer = plugin.outputCustomizer,
                let element = customizer.convert(paragraphProperty) {
                
                return element
            }
        }
        
        return nil
    }
}

