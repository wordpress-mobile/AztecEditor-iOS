import UIKit

extension Libxml2 {
    
    /// This class takes care of providing an interface for interacting with the DOM as if it Was
    /// a string.
    ///
    /// Any requests made to this class are performed in its own queue (sometimes synchronously,
    /// sometimes asynchronously).
    ///
    class DOMString {
        
        private lazy var editContext: EditContext = {
            return EditContext(undoManager: self.domUndoManager)
        }()
        
        private lazy var rootNode: RootNode = {
            
            let textNode = TextNode(text: "", editContext: self.editContext)
            
            return RootNode(children: [textNode], editContext: self.editContext)
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
            
            let converter = HTMLToAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor, editContext: editContext)
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
        ///
        func replaceCharacters(inRange range: NSRange, withString string: String) {

            let domHasModifications = range.length > 0 || string.characters.count > 0

            if domHasModifications {
                performAsyncUndoable { [weak self] in
                    self?.replaceCharactersSynchronously(inRange: range, withString: string)
                }
            }
        }
        
        // MARK: - Editing: Synchronously
        
        /// Replaces the specified range with a new string.
        ///
        /// - Parameters:
        ///     - range: the range of the original string to replace.
        ///     - string: the new string to replace the original text with.
        ///
        private func replaceCharactersSynchronously(inRange range: NSRange, withString string: String) {
            rootNode.replaceCharacters(inRange: range, withString: string)
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

        func remove(element: StandardElementType, at range: NSRange){
            performAsyncUndoable { [weak self] in
                self?.removeSynchronously(element: element, at: range)
            }
        }

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

        /// Disables blockquote from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        func removeBlockquote(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeBlockquoteSynchronously(spanning: range)
            }
        }
        
        // MARK: - Remove Styles: Synchronously
        private func removeSynchronously(element: StandardElementType, at range: NSRange) {

            guard range.length > 0 else {
                return
            }

            rootNode.unwrap(range: range, fromElementsNamed: element.equivalentNames)
        }

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

        private func removeBlockquoteSynchronously(spanning range: NSRange) {
            rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.blockquote.equivalentNames)
        }
        
        // Apply Styles
        
        /// Applies bold to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyBold(spanning range: NSRange) {
            applyElement(.strong, spanning: range)
        }
        
        /// Applies italic to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyItalic(spanning range: NSRange) {
            applyElement(.em, spanning: range)
        }
        
        /// Applies strikethrough to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyStrikethrough(spanning range: NSRange) {
            applyElement(.del, spanning: range)
        }
        
        /// Applies underline to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyUnderline(spanning range: NSRange) {
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
                    var components = [String]()
                    if let currentAttributes = element.valueForStringAttribute(named: "class") {
                        components = currentAttributes.components(separatedBy: CharacterSet.whitespaces)
                        components = components.filter({ (value) -> Bool in
                            return TextAttachment.Alignment.fromHTML(string: value.lowercased()) == nil && TextAttachment.Size.fromHTML(string: value.lowercased()) == nil
                        })

                    }
                    components.append(alignment.htmlString())
                    components.append(size.htmlString())
                    let classAttributes = components.joined(separator: " ")
                    element.updateAttribute(named: "class", value: classAttributes)
                    
                    if element.name == StandardElementType.img.rawValue {
                        element.updateAttribute(named: "src", value: url.absoluteString)
                    }
                }
            }
        }
    }
}
