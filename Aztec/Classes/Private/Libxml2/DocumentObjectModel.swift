import UIKit

extension Libxml2 {
    
    /// This class takes care of providing an interface for all DOM interaction.
    /// It also takes care of queueing all requests to the appropriate queue.
    ///
    class DocumentObjectModel {
        
        typealias RootNode = Libxml2.RootNode
        
        private var rootNode: RootNode = {
            return RootNode(children: [TextNode(text: "")])
        }()
        
        /// The queue that will be used for all DOM interaction operations.
        ///
        let domQueue = dispatch_queue_create("com.wordpress.domQueue", DISPATCH_QUEUE_SERIAL)
        
        // MARK: - Settings & Getting HTML
        
        /// Gets the HTML representation of the DOM.
        ///
        func getHTML() -> String {
            
            var result: String = ""
            
            dispatch_sync(domQueue) { [weak self] in
                
                guard let strongSelf = self else {
                    return
                }
                
                let converter = Libxml2.Out.HTMLConverter()
                result = converter.convert(strongSelf.rootNode)
            }
            
            return result
        }
        
        /// Sets the HTML for the DOM.
        ///
        /// - Parameters:
        ///     - html: the html to set.
        ///     - defaultFontDescriptor: the default font descriptor that will be used for the
        ///             output attributed string.
        ///
        /// - Returns: an attributed string representing the DOM contents.
        ///
        func setHTML(html: String, withDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) -> NSAttributedString {
            
            let converter = HTMLToAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor)
            let output: (rootNode: RootNode, attributedString: NSAttributedString)
            
            do {
                output = try converter.convert(html)
            } catch {
                fatalError("Could not convert the HTML.")
            }
            
            dispatch_sync(domQueue) {
                self.rootNode = output.rootNode
            }
            
            return output.attributedString
        }
        
        // MARK: - Editing
        
        /// Replaces the specified range with a new string.
        ///
        /// - Parameters:
        ///     - range: the range of the original string to replace.
        ///     - string: the new string to replace the original text with.
        ///     - inheritStyle: If `true` the new string will inherit the style information from the
        ///             first position in the specified range.  If `false`, the new sting will have
        ///             no associated style.
        ///
        func replaceCharacters(inRange range: NSRange, withString string: String, inheritStyle: Bool) {
            dispatch_async(domQueue) { [weak self] in
                self?.rootNode.replaceCharacters(inRange: range, withString: string, inheritStyle: inheritStyle)
            }
        }
        
        func replaceCharacters(inRange range: NSRange, withAttributedString attributedString: NSAttributedString, inheritStyle: Bool) {
            dispatch_async(domQueue) { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.rootNode.replaceCharacters(inRange: range, withString: attributedString.string, inheritStyle: inheritStyle)
                
                // remove all styles for the specified range here!
                
                let finalRange = NSRange(location: range.location, length: attributedString.length)
                strongSelf.applyStyles(from: attributedString, spanning: finalRange)
            }
        }
        
        func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
            dispatch_async(domQueue) { [weak self] in
                guard let strongSelf = self, attrs = attrs else {
                    return
                }
                
                strongSelf.applyStyles(from: attrs, spanning: range)
            }
        }
        
        // MARK: - Styles: Synchronization with DOM
        
        private func applyStyles(from attributes: [String : AnyObject], spanning range: NSRange) {
            for (key, value) in attributes {
                switch (key) {
                case NSAttachmentAttributeName:
                    applyStyle(attachmentValue: value, spanning: range)
                case NSFontAttributeName:
                    applyStyle(fontValue: value, spanning: range)
                case NSLinkAttributeName:
                    applyStyle(linkValue: value, spanning: range)
                case NSStrikethroughStyleAttributeName:
                    applyStyle(strikethroughValue: value, spanning: range)
                case NSUnderlineStyleAttributeName:
                    applyStyle(underlineValue: value, spanning: range)
                default:
                    break
                }
            }
        }
        
        /// Applies all styles from the specified attributed string and range to the DOM.
        ///
        /// - Parameters:
        ///     - attributedString: the string to get the attributes form.
        ///     - range: the range from which to take the styles to copy.
        ///
        private func applyStyles(from attributedString: NSAttributedString, spanning range: NSRange) {
            
            let options = NSAttributedStringEnumerationOptions(rawValue: 0)
            let fullRange = NSRange(location: 0, length: attributedString.length)
            
            attributedString.enumerateAttributesInRange(fullRange, options: options) { (attributes, range, stop) in
                applyStyles(from: attributes, spanning: range)
            }
        }
        
        /// Applies the attachment style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSAttachmentAttributeName` attribute.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(attachmentValue value: AnyObject, spanning range: NSRange) {
            guard let attachment = value as? TextAttachment else {
                assertionFailure("We're expecting a TextAttachment object here.  preprocessStyles should've curated this.")
                return
            }
            
            applyStyle(attachment, spanning: range)
        }
        
        /// Applies the attachment style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - attachmentValue: the value found in a `NSAttachmentAttributeName` attribute.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(attachment: TextAttachment, spanning range: NSRange) {
            setImageURLInDOM(attachment.url, forRange: range)
        }
        
        /// Applies the font style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSFontAttributeName` attribute.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(fontValue value: AnyObject, spanning range: NSRange) {
            
            guard let font = value as? UIFont else {
                assertionFailure("Was expecting a UIFont object as the value for the font attribute.")
                return
            }
            
            applyStyle(font, spanning: range)
        }
        
        /// Applies the font style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - font: the font to apply.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(font: UIFont, spanning range: NSRange) {
            
            let fontTraits = font.fontDescriptor().symbolicTraits
            
            if fontTraits.contains(.TraitBold) {
                applyBold(spanning: range)
            }
            
            if fontTraits.contains(.TraitItalic) {
                applyItalic(spanning: range)
            }
        }
        
        /// Applies the link style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSLinkAttributeName` attribute.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(linkValue value: AnyObject, spanning range: NSRange) {
            if let urlValue = value as? NSURL {
                applyStyle(urlValue, spanning: range)
            } else {
                guard let stringValue = value as? String,
                    let urlValue = NSURL(string: stringValue) else {
                        assertionFailure("Was expecting a NSString or NSURL object as the value for the link attribute.")
                        return
                }
                
                applyStyle(urlValue, spanning: range)
            }
        }
        
        /// Applies the link style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - linkURL: the URL to set for the link.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(linkURL: NSURL, spanning range: NSRange) {
            setLinkInDOM(range, url: linkURL)
        }
    
        /// Applies the strikethrough style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSStrikethroughStyleAttributeName` attribute.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(strikethroughValue value: AnyObject, spanning range: NSRange) {
            
            guard let intValue = value as? Int else {
                assertionFailure("The strikethrough style is always expected to be an Int.")
                return
            }
            
            guard let style = NSUnderlineStyle(rawValue: intValue) else {
                assertionFailure("The strikethrough style value is not-known.")
                return
            }
            
            applyStyle(strikethroughStyle: style, spanning: range)
        }
        
        /// Applies the strikethrough style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - style: the style of the strikethrough.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(strikethroughStyle style: NSUnderlineStyle, spanning range: NSRange) {
            
            switch (style) {
            case .StyleSingle:
                applyStrikethrough(spanning: range)
            default:
                // We don't support anything more than single-line strikethrough for now
                break
            }
        }
        
        /// Applies the underline style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSUnderlineStyleAttributeName` attribute.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(underlineValue value: AnyObject, spanning range: NSRange) {
            
            guard let intValue = value as? Int else {
                assertionFailure("The underline style is always expected to be an Int.")
                return
            }
            
            guard let style = NSUnderlineStyle(rawValue: intValue) else {
                assertionFailure("The underline style value is not-known.")
                return
            }
            
            applyStyle(underlineStyle: style, spanning: range)
        }
        
        /// Applies the underline style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - style: the style of the underline.
        ///     - range: the range the attribute is spanning.
        ///
        private func applyStyle(underlineStyle style: NSUnderlineStyle, spanning range: NSRange) {
            
            switch (style) {
            case .StyleSingle:
                applyUnderline(spanning: range)
            default:
                // We don't support anything more than single-line underline for now
                break
            }
        }
        
        // MARK: - Images
        
        private func setImageURLInDOM(imageURL: NSURL?, forRange range: NSRange) {
            
            let imageURLString = imageURL?.absoluteString ?? ""
            
            setImageURLStringInDOM(imageURLString, forRange: range)
        }
        
        private func setImageURLStringInDOM(imageURLString: String, forRange range: NSRange) {
            
            rootNode.replaceCharacters(inRange: range,
                                       withNodeNamed: StandardElementType.img.rawValue,
                                       withAttributes: [Libxml2.StringAttribute(name:"src", value: imageURLString)])
        }
        
        // MARK: - Links
        
        private func setLinkInDOM(range: NSRange, url: NSURL) {
            rootNode.wrapChildren(
                intersectingRange: range,
                inNodeNamed: StandardElementType.a.rawValue,
                withAttributes: [Libxml2.StringAttribute(name:"href", value: url.absoluteString!)],
                equivalentElementNames: StandardElementType.a.equivalentNames)
        }
        
        // MARK: Font Styles
        
        /// Disables bold from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        private func removeBold(spanning range: NSRange) {
            dispatch_async(domQueue) {
                self.rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.b.equivalentNames)
            }
        }
        
        /// Disables italic from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        private func removeItalic(spanning range: NSRange) {
            dispatch_async(domQueue) {
                self.rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.i.equivalentNames)
            }
        }
        
        /// Disables strikethrough from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        private func removeStrikethrough(spanning range: NSRange) {
            dispatch_async(domQueue) {
                self.rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.s.equivalentNames)
            }
        }
        
        /// Disables underline from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        private func removeUnderline(spanning range: NSRange) {
            dispatch_async(domQueue) {
                self.rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.u.equivalentNames)
            }
        }
        
        /// Applies bold to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        private func applyBold(spanning range: NSRange) {
            applyElement(
                StandardElementType.b.rawValue,
                spanning: range,
                equivalentElementNames: StandardElementType.b.equivalentNames)
        }
        
        /// Applies italic to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        private func applyItalic(spanning range: NSRange) {
            applyElement(
                StandardElementType.i.rawValue,
                spanning: range,
                equivalentElementNames: StandardElementType.i.equivalentNames)
        }
        
        /// Applies strikethrough to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        private func applyStrikethrough(spanning range: NSRange) {
            applyElement(
                StandardElementType.s.rawValue,
                spanning: range,
                equivalentElementNames:  StandardElementType.s.equivalentNames)
        }
        
        /// Applies underline to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        private func applyUnderline(spanning range: NSRange) {
            applyElement(
                StandardElementType.u.rawValue,
                spanning: range,
                equivalentElementNames:  StandardElementType.u.equivalentNames)
        }
        
        // MARK: - Styles to HTML elements
        
        /// Applies an HTML element to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the bold style to.
        ///
        private func applyElement(elementName: String, spanning range: NSRange, equivalentElementNames: [String]) {
            rootNode.wrapChildren(
                intersectingRange: range,
                inNodeNamed: elementName,
                withAttributes: [],
                equivalentElementNames: equivalentElementNames)
        }
        
        // MARK: - Candidates for removal
        
        func removeLink(inRange range: NSRange){
            dispatch_async(domQueue) { [weak self] in
                self?.rootNode.unwrap(range: range, fromElementsNamed: ["a"])
            }
        }
        
        func updateImage(spanning ranges: [NSRange], url: NSURL, size: TextAttachment.Size, alignment: TextAttachment.Alignment) {
            dispatch_async(domQueue) {
                for range in ranges {
                    let element = self.rootNode.lowestElementNodeWrapping(range)
                    if element.name == "img" {
                        let classAttributes = alignment.htmlString() + " " + size.htmlString()
                        element.updateAttribute(named: "class", value: classAttributes)
                        if let sourceURLString = url.absoluteString where element.name == "img" {
                            element.updateAttribute(named: "src", value: sourceURLString)
                        }
                    }
                }
            }
        }
    }
}
