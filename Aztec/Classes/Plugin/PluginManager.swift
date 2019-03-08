import Foundation
import UIKit

/// This class managed the loading and provides an execution interface for plugins.
///
class PluginManager {
    
    // MARK: - Plugin Loading
    
    private(set) var plugins = [Plugin]()
    
    /// Loads a plugins.
    ///
    func load(_ plugin: Plugin, in textView: TextView) {
        guard !plugins.contains(where: { $0 == plugin }) else {
            assertionFailure()
            return
        }
        
        plugins.append(plugin)
        plugin.loaded(textView: textView)
    }
    
    // MARK: - Input Processing
    
    /// Processes an HTML string right before parsing it to convert it into a nodes tree in
    /// the input conversion process.
    ///
    func process(html: String) -> String {
        return plugins.reduce(html) { (html, plugin) -> String in
            guard let customizer = plugin.inputCustomizer else {
                return html
            }
            
            return customizer.process(html: html)
        }
    }
    
    /// Processes a nodes tree right after it's been parsed from a string, and before finalizing
    /// the input conversion process.
    ///
    func process(htmlTree: RootNode) {
        for plugin in plugins {
            if let customizer = plugin.inputCustomizer {
                customizer.process(htmlTree: htmlTree)
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
            
            return customizer.process(html: html)
        }
    }
    
    /// Processes a nodes tree right before it'll bee converted to a string, and before finalizing
    /// the output conversion process.
    ///
    func process(outputHTMLTree tree: RootNode) {
        for plugin in plugins {
            if let customizer = plugin.outputCustomizer {
                customizer.process(htmlTree: tree)
            }
        }
    }
}

// MARK: - AttributedStringSerializerCustomizer

extension PluginManager: AttributedStringSerializerCustomizer {
    func converter(for element: ElementNode) -> ElementConverter? {
        for plugin in plugins {
            if let customizer = plugin.inputCustomizer,
                let converter = customizer.converter(for: element) as ElementConverter? {
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
    
    func convert(_ attachment: NSTextAttachment, attributes: [NSAttributedString.Key : Any]) -> [Node]? {
        for plugin in plugins {
            if let customizer = plugin.outputCustomizer,
                let elements = customizer.convert(attachment, attributes: attributes) {
                
                return elements
            }
        }
        
        return nil
    }
}

// MARK: - HTMLSerializerCustomizer

extension PluginManager: HTMLSerializerCustomizer {
    func converter(for element: ElementNode) -> ElementToTagConverter? {
        for plugin in plugins {
            if let customizer = plugin.outputCustomizer,
                let converter = customizer.converter(for: element) as ElementToTagConverter? {
                
                return converter
            }
        }
        
        return nil
    }
}

