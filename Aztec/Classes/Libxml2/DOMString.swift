import UIKit

extension Libxml2 {
    
    /// This class takes care of providing an interface for interacting with the DOM as if it Was
    /// a string.
    ///
    /// Any requests made to this class are performed in its own queue (sometimes synchronously,
    /// sometimes asynchronously).
    ///
    class DOMString {
        
        typealias UndoRegistrationClosure = Node.UndoRegistrationClosure
        
        private lazy var registerUndo: Node.UndoRegistrationClosure = { (undoTask: @escaping () -> ()) -> () in
            self.domUndoManager.registerUndo(withTarget: self, handler: { target in
                undoTask()
            })
        }
        
        private lazy var rootNode: RootNode = {
            
            let textNode = TextNode(text: "", registerUndo: self.registerUndo)
            
            return RootNode(children: [textNode], registerUndo: self.registerUndo)
        }()
        
        private var parentUndoManager: UndoManager?
        
        var undoManager: UndoManager? {
            get {
                return parentUndoManager
            }
            
            set {
                stopObservingParentUndoManager()
                parentUndoManager = newValue
                startObservingParentUndoManager()
            }
        }
        
        /// The private undo manager for the DOM.  This needs to be separated from the public undo
        /// manager because it'll be running in a separate dispatch queue, and undo managers "break"
        /// undo groups by run loops.
        ///
        /// This undo manager will respond to events in `parentUndoManager` to know when to execute
        /// an undo operation.
        ///
        private var domUndoManager = UndoManager()
        
        /// Parent undo manager observer for the undo event.
        ///
        private var undoObserver: NSObjectProtocol?
        
        /// Parent undo manager observer for the beginGroup event.
        ///
        private var beginGroupObserver: NSObjectProtocol?
        
        /// The queue that will be used for all DOM interaction operations.
        ///
        let domQueue = DispatchQueue(label: "com.wordpress.domQueue", attributes: [])
        
        // MARK: - Init & deinit
        
        deinit {
            stopObservingParentUndoManager()
        }
        
        // MARK: - Settings & Getting HTML
        
        /// Gets the HTML representation of the DOM.
        ///
        func getHTML() -> String {
            
            var result: String = ""
            
            domQueue.sync { [weak self] in
                
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
        func setHTML(_ html: String, withDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) -> NSAttributedString {
            
            let converter = HTMLToAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor, registerUndo: registerUndo)
            let output: (rootNode: RootNode, attributedString: NSAttributedString)
            
            do {
                output = try converter.convert(html)
            } catch {
                fatalError("Could not convert the HTML.")
            }
            
            domQueue.sync {
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
            
            performAsyncUndoable { [weak self] in
                self?.replaceCharactersSynchronously(inRange: range, withString: string, inheritStyle: inheritStyle)
            }
        }
        
        func replaceCharacters(inRange range: NSRange, withAttributedString attributedString: NSAttributedString, inheritStyle: Bool) {
            
            performAsyncUndoable { [weak self] in
                self?.replaceCharactersSynchronously(inRange: range, withAttributedString: attributedString, inheritStyle: inheritStyle)
            }
        }
        
        func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
            guard let attrs = attrs else {
                return
            }
            
            setAttributes(attrs, range: range)
        }
        
        func setAttributes(_ attrs: [String : Any], range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.setAttributesSynchronously(attrs: attrs, range: range)
            }
        }
        
        // MARK: - Editing: Synchronously
        
        /// Replaces the specified range with a new string.
        ///
        /// - Parameters:
        ///     - range: the range of the original string to replace.
        ///     - string: the new string to replace the original text with.
        ///     - inheritStyle: If `true` the new string will inherit the style information from the
        ///             first position in the specified range.  If `false`, the new sting will have
        ///             no associated style.
        ///
        private func replaceCharactersSynchronously(inRange range: NSRange, withString string: String, inheritStyle: Bool) {
            rootNode.replaceCharacters(inRange: range, withString: string, inheritStyle: inheritStyle)
        }

        private func replaceCharactersSynchronously(inRange range: NSRange, withAttributedString attributedString: NSAttributedString, inheritStyle: Bool) {
            
            rootNode.replaceCharacters(inRange: range, withString: attributedString.string, inheritStyle: inheritStyle)
            
            applyStyles(from: attributedString, to: range.location)
        }
        
        private func setAttributesSynchronously(attrs: [String: Any]?, range: NSRange) {
            guard let attrs = attrs else {
                return
            }
            
            applyStyles(from: attrs, to: range)
        }
        
        // MARK: - Undo Manager
        

        
        /// We have some special setup we need to take care of before registering undo operations.
        /// This method takes care of hooking up an undo operation in the client-provided undo
        /// manager with an undo operation in the DOM undo manager.
        ///
        /// Parameters:
        ///     - task: the task to execute that contains undo operations.
        ///
        private func performAsyncUndoable(task: @escaping () -> ()) {
            domQueue.async { [weak self] in
                
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.domUndoManager.beginUndoGrouping()
                task()
                strongSelf.domUndoManager.endUndoGrouping()
            }
        }
        
        /// Make our private undo manager start observing the parent undo manager.  This means
        /// our private undo manager will basically be connected to the parent one to know when
        /// to begin new undo groups, and perform undo operations.
        ///
        /// Redo operations don't need to be connected, as they can be executed completely through
        /// the parent undo manager (and normal edits to the DOM).
        ///
        private func startObservingParentUndoManager() {

            undoObserver = NotificationCenter.default.addObserver(forName: .NSUndoManagerDidUndoChange, object: parentUndoManager, queue: nil) { [weak self] notification in
                
                guard let strongSelf = self else {
                    return
                }
                
                if let undoManager = notification.object as? UndoManager, undoManager === strongSelf.parentUndoManager {
                    
                    let domUndoManager = strongSelf.domUndoManager
                    
                    domUndoManager.closeAllUndoGroups()
                    domUndoManager.undo()
                }
            }
            
            beginGroupObserver = NotificationCenter.default.addObserver(forName: .NSUndoManagerDidOpenUndoGroup, object: parentUndoManager, queue: nil) { [weak self] notification in
                
                guard let strongSelf = self else {
                    return
                }
                
                if let undoManager = notification.object as? UndoManager, undoManager === strongSelf.parentUndoManager {
                    
                    let domUndoManager = strongSelf.domUndoManager
                    
                    domUndoManager.closeAllUndoGroups()
                    domUndoManager.beginUndoGrouping()
                }
            }
        }
        
        /// Make our private undo manager stop observing the parent undo manager.
        ///
        private func stopObservingParentUndoManager() {
            
            if let beginGroupObserver = beginGroupObserver {
                NotificationCenter.default.removeObserver(beginGroupObserver)
                self.beginGroupObserver = nil
            }
            
            if let undoObserver = undoObserver {
                NotificationCenter.default.removeObserver(undoObserver)
                self.undoObserver = nil
            }
        }

        // MARK: - Styles: Synchronization with DOM
        
        /// Applies all styles from the specified attributes to the specified range in the DOM.
        ///
        /// - Parameters:
        ///     - attributes: the `NSAttributedString` attributes to apply.
        ///     - range: the range to apply those styles to.
        ///
        fileprivate func applyStyles(from attributes: [String : Any], to range: NSRange) {
            for (key, value) in attributes {
                switch (key) {
                case NSAttachmentAttributeName:
                    applyStyle(attachmentValue: value, to: range)
                case NSFontAttributeName:
                    applyStyle(fontValue: value, to: range)
                case NSLinkAttributeName:
                    applyStyle(linkValue: value, to: range)
                case NSStrikethroughStyleAttributeName:
                    applyStyle(strikethroughValue: value, to: range)
                case NSUnderlineStyleAttributeName:
                    applyStyle(underlineValue: value, to: range)
                case NSParagraphStyleAttributeName:
                    applyStyle(paragraphStyle: value, to:range)
                default:
                    break
                }
            }
        }
        
        /// Applies all styles from the specified attributed string to the specified range in the
        /// DOM.
        ///
        /// - Parameters:
        ///     - attributedString: the string to get the attributes form.
        ///     - location: the location where the attributes from the string must be applied.
        ///
        fileprivate func applyStyles(from attributedString: NSAttributedString, to location: Int) {
            
            let options = NSAttributedString.EnumerationOptions(rawValue: 0)
            let sourceRange = NSRange(location: 0, length: attributedString.length)
            
            attributedString.enumerateAttributes(in: sourceRange, options: options) { (attributes, sourceSubrange, stop) in
                
                let subrangeWithOffset = NSRange(location: location + sourceSubrange.location, length: sourceSubrange.length)
                applyStyles(from: attributes as [String : AnyObject], to: subrangeWithOffset)
            }
        }
        
        /// Applies the attachment style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSAttachmentAttributeName` attribute.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(attachmentValue value: Any, to range: NSRange) {
            guard let attachment = value as? TextAttachment else {
                assertionFailure("We're expecting a TextAttachment object here.  preprocessStyles should've curated this.")
                return
            }
            
            applyStyle(attachment, to: range)
        }
        
        /// Applies the attachment style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - attachmentValue: the value found in a `NSAttachmentAttributeName` attribute.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(_ attachment: TextAttachment, to range: NSRange) {
            setImageURLInDOM(attachment.url as URL?, forRange: range)
        }
        
        /// Applies the font style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSFontAttributeName` attribute.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(fontValue value: Any, to range: NSRange) {
            
            guard let font = value as? UIFont else {
                assertionFailure("Was expecting a UIFont object as the value for the font attribute.")
                return
            }
            
            applyStyle(font, to: range)
        }
        
        /// Applies the font style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - font: the font to apply.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(_ font: UIFont, to range: NSRange) {
            
            let fontTraits = font.fontDescriptor.symbolicTraits
            
            if fontTraits.contains(.traitBold) {
                applyBold(spanning: range)
            }
            
            if fontTraits.contains(.traitItalic) {
                applyItalic(spanning: range)
            }
        }
        
        /// Applies the link style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSLinkAttributeName` attribute.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(linkValue value: Any, to range: NSRange) {
            if let urlValue = value as? URL {
                applyStyle(urlValue, to: range)
            } else {
                guard let stringValue = value as? String,
                    let urlValue = URL(string: stringValue) else {
                        assertionFailure("Was expecting a NSString or NSURL object as the value for the link attribute.")
                        return
                }
                
                applyStyle(urlValue, to: range)
            }
        }
        
        /// Applies the link style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - linkURL: the URL to set for the link.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(_ linkURL: URL, to range: NSRange) {
            setLinkInDOM(range, url: linkURL)
        }
    
        /// Applies the strikethrough style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - value: the value found in a `NSStrikethroughStyleAttributeName` attribute.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(strikethroughValue value: Any, to range: NSRange) {
            
            guard let intValue = value as? Int else {
                assertionFailure("The strikethrough style is always expected to be an Int.")
                return
            }
            
            guard let style = NSUnderlineStyle(rawValue: intValue) else {
                assertionFailure("The strikethrough style value is not-known.")
                return
            }
            
            applyStyle(strikethroughStyle: style, to: range)
        }
        
        /// Applies the strikethrough style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - style: the style of the strikethrough.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(strikethroughStyle style: NSUnderlineStyle, to range: NSRange) {
            
            switch (style) {
            case .styleSingle:
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
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(underlineValue value: Any, to range: NSRange) {
            
            guard let intValue = value as? Int else {
                assertionFailure("The underline style is always expected to be an Int.")
                return
            }
            
            guard let style = NSUnderlineStyle(rawValue: intValue) else {
                assertionFailure("The underline style value is not-known.")
                return
            }
            
            applyStyle(underlineStyle: style, to: range)
        }
        
        /// Applies the underline style spanning the specified range to the DOM.
        ///
        /// - Parameters:
        ///     - style: the style of the underline.
        ///     - range: the range the style will be applied to.
        ///
        fileprivate func applyStyle(underlineStyle style: NSUnderlineStyle, to range: NSRange) {
            
            switch (style) {
            case .styleSingle:
                applyUnderline(spanning: range)
            default:
                // We don't support anything more than single-line underline for now
                break
            }
        }

        fileprivate func applyStyle(paragraphStyle value: Any, to range: NSRange) {
            guard let paragraphStyle = value as? ParagraphStyle else {
                // if the value is not a Aztec ParagraphStyle we ignore it
                return
            }
            applyStyle(paragraphStyle: paragraphStyle, to: range)
        }

        fileprivate func applyStyle(paragraphStyle: ParagraphStyle, to range: NSRange) {
            if paragraphStyle.blockquote != nil {
                applyElement(.blockquote, spanning: range)
            }
        }
        
        // MARK: - Images
        
        fileprivate func setImageURLInDOM(_ imageURL: URL?, forRange range: NSRange) {
            
            let imageURLString = imageURL?.absoluteString ?? ""
            
            setImageURLStringInDOM(imageURLString, forRange: range)
        }
        
        fileprivate func setImageURLStringInDOM(_ imageURLString: String, forRange range: NSRange) {
            
            let elementDescriptor = ElementNodeDescriptor(elementType: .img,
                                                          attributes: [Libxml2.StringAttribute(name:"src", value: imageURLString)])
            
            rootNode.replaceCharacters(inRange: range, withElement: elementDescriptor)
        }
        
        // MARK: - Links
        
        fileprivate func setLinkInDOM(_ range: NSRange, url: URL) {
            
            let elementDescriptor = ElementNodeDescriptor(elementType: .a,
                                                          attributes: [Libxml2.StringAttribute(name:"href", value: url.absoluteString)])
            
            rootNode.wrapChildren(intersectingRange: range, inElement: elementDescriptor)
        }

        // MARK: Remove Styles

        /// Disables bold from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        func removeBold(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeBoldSynchronously(spanning: range)
            }
        }

        /// Disables italic from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        func removeItalic(spanning range: NSRange) {
            //domQueue.async { [weak self] in
            performAsyncUndoable { [weak self] in
                self?.removeItalicSynchronously(spanning: range)
            }
        }

        /// Disables strikethrough from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        func removeStrikethrough(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeStrikethroughSynchronously(spanning: range)
            }
        }

        /// Disables underline from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        func removeUnderline(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeUnderlineSynchronously(spanning: range)
            }
        }
        
        // MARK: - Remove Styles: Synchronously
        
        private func removeBoldSynchronously(spanning range: NSRange) {
            rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.b.equivalentNames)
        }
        
        private func removeItalicSynchronously(spanning range: NSRange) {
            rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.i.equivalentNames)
        }
        
        private func removeStrikethroughSynchronously(spanning range: NSRange) {
            rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.s.equivalentNames)
        }
        
        private func removeUnderlineSynchronously(spanning range: NSRange) {
            rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.u.equivalentNames)
        }
        
        // Apply Styles
        
        /// Applies bold to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        fileprivate func applyBold(spanning range: NSRange) {
            applyElement(.b, spanning: range)
        }
        
        /// Applies italic to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        fileprivate func applyItalic(spanning range: NSRange) {
            applyElement(.i, spanning: range)
        }
        
        /// Applies strikethrough to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        fileprivate func applyStrikethrough(spanning range: NSRange) {
            applyElement(.s, spanning: range)
        }
        
        /// Applies underline to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        fileprivate func applyUnderline(spanning range: NSRange) {
            applyElement(.u, spanning: range)
        }
        
        // MARK: - Styles to HTML elements
        
        /// Applies a standard HTML element to the specified range.
        ///
        /// Whenever applying a standard element type, use this method.
        ///
        /// - Parameters:
        ///     - elementType: the standard element type to apply.
        ///     - range: the range to apply the bold style to.
        ///
        fileprivate func applyElement(_ elementType: StandardElementType, spanning range: NSRange) {
            applyElement(elementType.rawValue, spanning: range, equivalentElementNames: elementType.equivalentNames)
        }
        
        /// Applies an HTML element to the specified range.
        ///
        /// Use this method directly only when applying custom element types (non standard).
        ///
        /// - Parameters:
        ///     - elementName: the element name to apply
        ///     - range: the range to apply the bold style to.
        ///     - equivalentElementNames: equivalent element names to look for before applying
        ///             the specified one.
        ///
        fileprivate func applyElement(_ elementName: String, spanning range: NSRange, equivalentElementNames: [String]) {
            
            let elementDescriptor = ElementNodeDescriptor(name: elementName, attributes: [], matchingNames: equivalentElementNames)
            rootNode.wrapChildren(intersectingRange: range, inElement: elementDescriptor)
        }
        
        // MARK: - Candidates for removal
        
        func removeLink(inRange range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeLinkSynchronously(inRange: range)
            }
        }
        
        func updateImage(spanning ranges: [NSRange], url: URL, size: TextAttachment.Size, alignment: TextAttachment.Alignment) {
            performAsyncUndoable { [weak self] in
                self?.updateImageSynchronously(spanning: ranges, url: url, size: size, alignment: alignment)
            }
        }
        
        // MARK: - Candidates for removal: Synchronously
        
        private func removeLinkSynchronously(inRange range: NSRange) {
            rootNode.unwrap(range: range, fromElementsNamed: ["a"])
        }
        
        private func updateImageSynchronously(spanning ranges: [NSRange], url: URL, size: TextAttachment.Size, alignment: TextAttachment.Alignment) {
            
            for range in ranges {
                let element = self.rootNode.lowestElementNodeWrapping(range)
                
                if element.name == StandardElementType.img.rawValue {
                    let classAttributes = alignment.htmlString() + " " + size.htmlString()
                    element.updateAttribute(named: "class", value: classAttributes)
                    
                    if element.name == StandardElementType.img.rawValue {
                        element.updateAttribute(named: "src", value: url.absoluteString)
                    }
                }
            }
        }
    }
}
