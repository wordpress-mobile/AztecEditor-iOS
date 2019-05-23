import UIKit


/// Converts a generic element to `NSAttributedString`.  Should only be used if a specific converter is not found.
///
class GenericElementConverter: ElementConverter {
    
    // MARK: - Element Support
    
    /// This is a list of elements that don't produce an HTML attachment when they go through this converter
    /// At some point we should modify how the conversion works, so that any supported element never goes through this
    /// converter at all, and this converter is turned into an `UnsupportedElementConverter()` exclusively.
    ///
    private static let supportedElements: [Element] = [.a, .aztecRootNode, .b, .br, .blockquote, .del, .div, .em, .figure, .figcaption, .h1, .h2, .h3, .h4, .h5, .h6, .hr, .i, .img, .li, .ol, .p, .pre, .s, .span, .strike, .strong, .u, .ul, .video, .code]
    
    // MARK: - Built-in formatter instances
    
    lazy var blockquoteFormatter = BlockquoteFormatter()
    lazy var boldFormatter = BoldFormatter()
    lazy var divFormatter = HTMLDivFormatter()
    lazy var h1Formatter = HeaderFormatter(headerLevel: .h1)
    lazy var h2Formatter = HeaderFormatter(headerLevel: .h2)
    lazy var h3Formatter = HeaderFormatter(headerLevel: .h3)
    lazy var h4Formatter = HeaderFormatter(headerLevel: .h4)
    lazy var h5Formatter = HeaderFormatter(headerLevel: .h5)
    lazy var h6Formatter = HeaderFormatter(headerLevel: .h6)
    lazy var italicFormatter = ItalicFormatter()
    lazy var linkFormatter = LinkFormatter()
    lazy var orderedListFormatter = TextListFormatter(style: .ordered, increaseDepth: true)
    lazy var paragraphFormatter = HTMLParagraphFormatter()
    lazy var preFormatter = PreFormatter()
    lazy var strikethroughFormatter = StrikethroughFormatter()
    lazy var underlineFormatter = UnderlineFormatter()
    lazy var unorderedListFormatter = TextListFormatter(style: .unordered, increaseDepth: true)
    lazy var codeFormatter = CodeFormatter()
    lazy var liFormatter = LiFormatter()
    
    public lazy var elementFormattersMap: [Element: AttributeFormatter] = {
        return [
            .blockquote: self.blockquoteFormatter,
            .div: self.divFormatter,
            .ol: self.orderedListFormatter,
            .ul: self.unorderedListFormatter,
            .strong: self.boldFormatter,
            .em: self.italicFormatter,
            .u: self.underlineFormatter,
            .del: self.strikethroughFormatter,
            .a: self.linkFormatter,
            .h1: self.h1Formatter,
            .h2: self.h2Formatter,
            .h3: self.h3Formatter,
            .h4: self.h4Formatter,
            .h5: self.h5Formatter,
            .h6: self.h6Formatter,
            .p: self.paragraphFormatter,
            .pre: self.preFormatter,
            .code: self.codeFormatter,
            .li: self.liFormatter
        ]
    }()
    
    // MARK: - ElementConverter
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString {
        
        guard isSupportedByEditor(element) else {
            return convert(unsupported: element, inheriting: attributes)
        }
        
        return convert(supported: element, inheriting: attributes, contentSerializer: serialize)
    }
    
    private func isSupportedByEditor(_ element: ElementNode) -> Bool {
        return GenericElementConverter.supportedElements.contains(element.type)
    }
    
    /// Converts an unsupported `ElementNode` into it's `NSAttributedString` representation.
    /// This method basically packs the `ElementNode` into an attachment, making it completely
    /// safe against data loss.  All attributes and children will be perfectly stored.
    ///
    /// - Parameters:
    ///     - element: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    private func convert(
        unsupported element: ElementNode,
        inheriting attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        
        let serializer = HTMLSerializer()
        let attachment = HTMLAttachment()
        
        attachment.rootTagName = element.name
        attachment.rawHTML = serializer.serialize(element)
        
        let content = NSMutableAttributedString(attachment: attachment, attributes: attributes)
        
        if element.needsClosingParagraphSeparatorIncludingDescendants() {
            content.append(NSAttributedString(.paragraphSeparator, attributes: attributes))
        }
        
        return content
    }
    
    private func convert(
        supported element: ElementNode,
        inheriting inheritedAttributes: [NSAttributedString.Key: Any],
        contentSerializer serialize: ContentSerializer) -> NSAttributedString {
        
        let childrenAttributes = attributes(for: element, inheriting: inheritedAttributes)
        
        return serialize(element, nil, childrenAttributes, false)
    }
}

private extension GenericElementConverter {
    
    // MARK: - NSAttributedString attribute generation
    
    /// Calculates the attributes for the specified node.  Returns a dictionary including inherited
    /// attributes.
    ///
    /// - Parameters:
    ///     - element: the node to get the information from.
    ///     - inheritedAttributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    func attributes(for element: ElementNode, inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        
        guard !(element is RootNode) else {
            return inheritedAttributes
        }
        
        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        var finalAttributes: [NSAttributedString.Key: Any]
        
        if let elementFormatter = formatter(for: element) {
            finalAttributes = elementFormatter.apply(to: inheritedAttributes, andStore: representation)
        } else {
            finalAttributes = attributes(storing: elementRepresentation, in: inheritedAttributes)
        }
        
        return finalAttributes
    }
    
    /// Calculates the attributes for the specified HTML attributes.  Returns a dictionary
    /// including the inherited attributes.
    ///
    /// - Parameters:
    ///     - htmlAttributes: the HTML attributes to calculate the string attributes from.
    ///     - inheritedAttributes: the attributes that will be inherited.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    private func attributes(for htmlAttributes: [Attribute], inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        
        let finalAttributes = htmlAttributes.reduce(inheritedAttributes) { (previousAttributes, htmlAttribute) -> [NSAttributedString.Key: Any] in
            return attributes(for: htmlAttribute, inheriting: previousAttributes)
        }
        
        return finalAttributes
    }
    
    
    /// Calculates the attributes for the specified HTML attribute.  Returns a dictionary
    /// including inherited attributes.
    ///
    /// - Parameters:
    ///     - attribute: the attribute to calculate the string attributes from.
    ///     - inheritedAttributes: the attributes that will be inherited.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    private func attributes(for attribute: Attribute, inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        
        let attributes: [NSAttributedString.Key: Any]
        
        if let attributeFormatter = formatter(for: attribute) {
            let attributeHTMLRepresentation = HTMLRepresentation(for: .attribute(attribute))
            
            attributes = attributeFormatter.apply(to: inheritedAttributes, andStore: attributeHTMLRepresentation)
        } else {            
            attributes = inheritedAttributes
        }
        
        return attributes
    }
    
    
    /// Stores the specified HTMLElementRepresentation in a collection of NSAttributedString Attributes.
    ///
    /// - Parameters:
    ///     - representation: Instance of HTMLElementRepresentation to be stored.
    ///     - attributes: Attributes where we should store the HTML Representation.
    ///
    /// - Returns: A collection of NSAttributedString Attributes, including the specified HTMLElementRepresentation.
    ///
    private func attributes(storing representation: HTMLElementRepresentation, in attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        let unsupportedHTML = attributes[.unsupportedHtml] as? UnsupportedHTML
        var representations = unsupportedHTML?.representations ?? []
        representations.append(representation)
        
        // Note:
        // We'll *ALWAYS* store a copy of the UnsupportedHTML instance. Reason is: reusing the old instance
        // would mean affecting a range that may fall beyond what we expected!
        //
        var updated = attributes
        updated[.unsupportedHtml] = UnsupportedHTML(representations: representations)
        
        return updated
    }
}

// MARK: - Attribute formatters

private extension GenericElementConverter {
    
    // MARK: - Formatters
    
    func formatter(for attribute: Attribute) -> AttributeFormatter? {
        // TODO: implement attribute representation formatters
        //
        return nil
    }
    
    func formatter(for element: ElementNode) -> AttributeFormatter? {
        let equivalentNames = element.type.equivalentNames
        
        for (key, formatter) in elementFormattersMap {
            if equivalentNames.contains(key) {
                return formatter
            }
        }
        
        return nil
    }
    
}

