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

    /// If a value is set the character set will be used to replace any last empty line created by the converter.
    ///
    open var characterToReplaceLastEmptyLine: Character?

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
        var attributedString = treeToAttributedString.serialize(rootNode, defaultAttributes: defaultAttributes)

        if let characterToUse = characterToReplaceLastEmptyLine {
            attributedString = replaceLastEmptyLine(in: attributedString, with: characterToUse)
        }
        
        return attributedString
    }

    func replaceLastEmptyLine(in attributedString: NSAttributedString, with replacement: Character) -> NSAttributedString {
        var result = attributedString
        let string = attributedString.string
        if !string.isEmpty, string.isEmptyLineAtEndOfFile(at: string.count), string.hasSuffix(String(.paragraphSeparator)), let location = string.location(before: attributedString.length) {
            let mutableString = NSMutableAttributedString(attributedString: attributedString)
            let attributes = mutableString.attributes(at: location, effectiveRange: nil)
            mutableString.replaceCharacters(in: NSRange(location: location, length: attributedString.length-location), with: NSAttributedString(string: String(replacement), attributes: attributes))
            result = mutableString
        }
        return result
    }


    /// Check if the given html string is supported to be parsed into Attributed Strings.
    ///
    /// In some cases, like pasting from the Notes app, the generated HTML will have a `<body>` tag, and that
    /// is not yet supported. In those cases is preferible to abort html parsing.
    ///
    /// - Parameter html: The html string to check.
    /// - Returns: A bool value indicating if the given html string can be handled correctly.
    ///
    func isSupported(_ html: String) -> Bool {
        let processedHTML = pluginManager.process(html: html)
        let rootNode = htmlToTree.parse(processedHTML)
        return hasBodyNode(rootNode.children) == false
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

// MARK: - Helpers

private extension HTMLConverter {
    func hasBodyNode(_ nodes: [Node]) -> Bool {
        return hasBodyNode(ArraySlice<Node>(nodes))
    }

    private func hasBodyNode(_ nodes: ArraySlice<Node>) -> Bool {
        if nodes.isEmpty {
            return false
        }

        switch nodes.first {
        case let element as ElementNode where element.name == Element.body.rawValue:
            return true
        default:
            return hasBodyNode(nodes.dropFirst())
        }
    }
}
