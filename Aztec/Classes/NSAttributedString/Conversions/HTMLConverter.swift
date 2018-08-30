import Foundation

/// This is the main converter class in Aztec.
/// It takes care of converting HTML text to NSAttributedString and vice-versa.
///
public class HTMLConverter {
    
    // MARK: - Plugins & Parsing
    
    let pluginManager: PluginManager
    
    // MARK: - Initializers
    
    public init() {
        pluginManager = PluginManager()
    }
    
    init(with pluginManager: PluginManager) {
        self.pluginManager = pluginManager
    }
    
    // MARK: - Converters: HTML -> AttributedString
    
    let htmlToTree = HTMLParser()
    
    private(set) lazy var treeToAttributedString: AttributedStringSerializer = {
        return AttributedStringSerializer(customizer: pluginManager)
    }()
    
    // MARK: - Converters: AttributedString -> HTML
    
    private(set) lazy var attributedStringToTree: AttributedStringParser = {
        return AttributedStringParser(customizer: pluginManager)
    }()
    
    private(set) lazy var treeToHTML: HTMLSerializer = {
        return HTMLSerializer(customizer: pluginManager)
    }()
    
    // MARK: - Conversion Logic
    
    /// Converts an HTML string into it's `NSAttributedString` representation.
    ///
    /// - Parameters:
    ///     - html: the html string.
    ///     - defaultAttributes: the default attributes for the attributed string.
    ///
    /// - Returns: the attributed string that represents the provided HTML.
    ///
    func attributedString(from html: String, defaultAttributes: [NSAttributedString.Key: Any]? = [:]) -> NSAttributedString {
        let processedHTML = pluginManager.process(html: html)
        let rootNode = htmlToTree.parse(processedHTML)
        
        pluginManager.process(htmlTree: rootNode)
        
        let defaultAttributes = defaultAttributes ?? [:]
        let attributedString = treeToAttributedString.serialize(rootNode, defaultAttributes: defaultAttributes)
        
        return attributedString
    }
    
    /// Converts an attributed string string into it's HTML string representation.
    ///
    /// - Parameters:
    ///     - attributedString: the attributed string
    ///     - prettify: whether the output should be prettified.
    ///
    /// - Returns: the HTML string that represents the provided `NSAttributedString`.
    ///
    func html(from attributedString: NSAttributedString, prettify: Bool = false) -> String {
        let rootNode = attributedStringToTree.parse(attributedString)
        
        pluginManager.process(outputHTMLTree: rootNode)
        
        let html = treeToHTML.serialize(rootNode, prettify: prettify)
        
        return pluginManager.process(outputHTML: html)
    }
    
}
