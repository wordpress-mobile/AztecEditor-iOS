import UIKit

extension Libxml2 {
    
    /// This class takes care of providing an interface for interacting with the DOM as if it Was
    /// a string.
    ///
    /// Any requests made to this class are performed in its own queue (sometimes synchronously,
    /// sometimes asynchronously).  Public methods are resopnsible for queueing requests, while all
    /// private methods MUST be synchronous.  This is to ensure a simple design in which we are sure
    /// we're not queueing an operation more than once.  Private methods can be called without
    /// having to figure out if they'll be queueing additional operations (they won't).
    ///
    class DOMString {

        private static let headerLevels: [StandardElementType] = [.h1, .h2, .h3, .h4, .h5, .h6]

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

        // MARK: - Properties: DOM Logic

        private lazy var domEditor: DOMEditor = {
            return DOMEditor(with: self.rootNode)
        }()
        
        // MARK: - Init & deinit
        
        deinit {
            stopObservingParentUndoManager()
        }

        // MARK: - String representation

        func string() -> String {
            var result: String = ""

            domQueue.sync { [weak self] in

                guard let strongSelf = self else {
                    return
                }

                result = strongSelf.rootNode.text()
            }

            return result
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
                self.domEditor = DOMEditor(with: output.rootNode)
            }
            
            return output.attributedString
        }
        
        // MARK: - Editing

        /// Deletes a block-level elements separator at the specified location.
        ///
        /// - Parameters:
        ///     - location: the location of the block-level element separation we want to remove.
        ///
        func deleteBlockSeparator(at location: Int) {
            performAsyncUndoable { [weak self] in
                self?.deleteBlockSeparatorSynchronously(at: location)
            }
        }

        /// Replaces the specified range with a new string.
        ///
        /// - Parameters:
        ///     - range: the range of the original string to replace.
        ///     - string: the new string to replace the original text with.
        ///
        func replaceCharacters(inRange range: NSRange, withString string: String, preferLeftNode: Bool) {
            
            let domHasModifications = range.length > 0 || !string.isEmpty

            if domHasModifications {
                performAsyncUndoable { [weak self] in
                    self?.replaceCharactersSynchronously(inRange: range, withString: string, preferLeftNode: preferLeftNode)
                }
            }
        }
        
        // MARK: - Editing: Synchronously

        /// Deletes a block-level elements separator at the specified location.
        ///
        /// - Parameters:
        ///     - location: the location of the block-level element separation we want to remove.
        ///
        private func deleteBlockSeparatorSynchronously(at location: Int) {
            domEditor.mergeBlockLevelElementRight(endingAt: location)
        }

        /// Replaces the specified range with a new string.
        ///
        /// - Parameters:
        ///     - range: the range of the original string to replace.
        ///     - string: the new string to replace the original text with.
        ///
        private func replaceCharactersSynchronously(inRange range: NSRange, withString string: String, preferLeftNode: Bool) {
            rootNode.replaceCharacters(inRange: range, withString: string, preferLeftNode: preferLeftNode)
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

        // MARK: - Remove Styles

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

        /// Removes an image from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        func removeImage(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeImageSynchronously(spanning: range)
            }
        }

        /// Removes an video from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        func removeVideo(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeVideoSynchronously(spanning: range)
            }
        }

        /// Disables italic from the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to remove the style from.
        ///
        func removeItalic(spanning range: NSRange) {
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

        /// Disables link from the specified range
        ///
        /// - Parameter range: the range to remove
        ///
        func removeLink(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeSynchronously(element:.a, at: range)
            }
        }

        func removeHeader(_ headerLevel: Int, spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.removeHeaderSynchronously(headerLevel: headerLevel, spanning: range)
            }
        }
        
        // MARK: - Remove Styles: Synchronously
        private func removeSynchronously(element: StandardElementType, at range: NSRange) {

            guard range.length > 0 else {
                return
            }

            domEditor.unwrap(range: range, fromElementsNamed: element.equivalentNames)
        }

        private func removeBoldSynchronously(spanning range: NSRange) {
            domEditor.unwrap(range: range, fromElementsNamed: StandardElementType.b.equivalentNames)
        }

        private func removeImageSynchronously(spanning range: NSRange) {
            domEditor.unwrap(range: range, fromElementsNamed: StandardElementType.img.equivalentNames)
        }

        private func removeVideoSynchronously(spanning range: NSRange) {
            domEditor.unwrap(range: range, fromElementsNamed: StandardElementType.video.equivalentNames)
        }
        
        private func removeItalicSynchronously(spanning range: NSRange) {
            domEditor.unwrap(range: range, fromElementsNamed: StandardElementType.i.equivalentNames)
        }
        
        private func removeStrikethroughSynchronously(spanning range: NSRange) {
            domEditor.unwrap(range: range, fromElementsNamed: StandardElementType.s.equivalentNames)
        }
        
        private func removeUnderlineSynchronously(spanning range: NSRange) {
            domEditor.unwrap(range: range, fromElementsNamed: StandardElementType.u.equivalentNames)
        }

        private func removeBlockquoteSynchronously(spanning range: NSRange) {
            domEditor.unwrap(range: range, fromElementsNamed: StandardElementType.blockquote.equivalentNames)
        }

        private func removeHeaderSynchronously(headerLevel: Int, spanning range: NSRange) {
            guard let elementType = elementTypeForHeaderLevel(headerLevel) else {
                return
            }
            domEditor.unwrap(range: range, fromElementsNamed: elementType.equivalentNames)
        }
        
        // MARK: - Apply Styles
                
        /// Applies bold to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyBold(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.applyElement(.strong, spanning: range)
            }
        }
        
        /// Applies italic to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyItalic(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.applyElement(.em, spanning: range)
            }
        }
        
        /// Applies strikethrough to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyStrikethrough(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.applyElement(.del, spanning: range)
            }
        }
        
        /// Applies underline to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyUnderline(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.applyElement(.u, spanning: range)
            }
        }

        /// Applies blockquote to the specified range.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func applyBlockquote(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.applyElement(.blockquote, spanning: range)
            }
        }

        /// Applies a link to the specified range
        ///
        /// - Parameters:
        ///   - url: the url to link to
        ///   - range: the range to apply the link
        ///
        func applyLink(_ url: URL?, spanning range: NSRange) {
            var attributes: [Libxml2.Attribute] = []
            if let url = url {
                attributes.append(Libxml2.StringAttribute(name: HTMLLinkAttribute.Href.rawValue, value: url.absoluteString))
            }
            performAsyncUndoable { [weak self] in
                self?.applyElement(.a, spanning: range, attributes: attributes)
            }
        }

        func applyOrderedList(spanning range: NSRange) {
            performAsyncUndoable { [weak self] in

                let liDescriptor = ElementNodeDescriptor(elementType: .li)
                let olDescriptor = ElementNodeDescriptor(elementType: .ol, childDescriptor: liDescriptor)

                self?.applyElementDescriptor(olDescriptor, spanning: range)
            }
        }

        func applyHeader(_ headerLevel:Int, spanning range:NSRange) {
            guard let elementType = elementTypeForHeaderLevel(headerLevel) else {
                return
            }
            performAsyncUndoable { [weak self] in
                self?.applyElement(elementType, spanning: range)
            }
        }

        // MARK: - Header types

        private func elementTypeForHeaderLevel(_ headerLevel: Int) -> StandardElementType? {
            if headerLevel < 1 && headerLevel > DOMString.headerLevels.count {
                return nil
            }
            return DOMString.headerLevels[headerLevel - 1]
        }

        // MARK: - Raw HTML

        /// Replaces the specified range with a given Raw HTML String.
        ///
        /// - Parameters:
        ///   - range: the range to insert the HTML
        ///   - rawHTML: String representing a raw HTML Snippet, to be converted into Nodes.
        ///
        func replace(_ range: NSRange, withRawHTML rawHTML: String) {
            performAsyncUndoable { [weak self] in
                self?.replaceSynchronously(range, withRawHTML: rawHTML)
            }
        }

        private func replaceSynchronously(_ range: NSRange, withRawHTML rawHTML: String) {
            do {
                let htmlToNode = Libxml2.In.HTMLConverter(editContext: editContext)
                let parsedRootNode = try htmlToNode.convert(rawHTML)

                guard let firstChild = parsedRootNode.children.first else {
                    return
                }
                rootNode.replaceCharacters(in: range, with: firstChild)
            } catch {
                fatalError("Could not replace range with raw HTML: \(rawHTML).")
            }
        }

        // MARK: - Images

        /// Replaces the specified range with a given image.
        ///
        /// - Parameters:
        ///   - range: the range to insert the image
        ///   - imageURL: the URL for the img src attribute
        ///
        func replace(_ range: NSRange, with imageURL: URL) {
            performAsyncUndoable { [weak self] in
                self?.replaceSynchronously(range, with: imageURL)
            }
        }

        private func replaceSynchronously(_ range: NSRange, with imageURL: URL) {
            let imageURLString = imageURL.absoluteString

            let attributes = [Libxml2.StringAttribute(name:"src", value: imageURLString)]
            let descriptor = ElementNodeDescriptor(elementType: .img, attributes: attributes)

            rootNode.replaceCharacters(in: range, with: descriptor)
        }

        // MARK: - Videos

        /// Replaces the specified range with a given image.
        ///
        /// - Parameters:
        ///   - range: the range to insert the image
        ///   - videoURL: the URL for the video src attribute
        ///   - posterURL: the URL for ther video poster attribute
        ///
        func replace(_ range: NSRange, withVideoURL videoURL: URL, posterURL: URL?) {
            performAsyncUndoable { [weak self] in
                self?.replaceSynchronously(range, withVideoURL: videoURL, posterURL: posterURL)
            }
        }

        private func replaceSynchronously(_ range: NSRange, withVideoURL videoURL: URL, posterURL: URL?) {
            let videoURLString = videoURL.absoluteString

            var attributes = [Libxml2.StringAttribute(name:"src", value: videoURLString)]
            if let posterURLString = posterURL?.absoluteString {
                attributes.append(Libxml2.StringAttribute(name:"poster", value: posterURLString))
            }
            let descriptor = ElementNodeDescriptor(elementType: .video, attributes: attributes)

            rootNode.replaceCharacters(in: range, with: descriptor)
        }

        /// Replaces the specified range with a Horizontal Ruler Style.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///
        func replaceWithHorizontalRuler(_ range: NSRange) {
            performAsyncUndoable { [weak self] in
                self?.replaceSynchronouslyWithHorizontalRulerStyle(range)
            }
        }

        private func replaceSynchronouslyWithHorizontalRulerStyle(_ range: NSRange) {
            let descriptor = ElementNodeDescriptor(elementType: .hr)

            rootNode.replaceCharacters(in: range, with: descriptor)
        }

        /// Replaces the specified range with a Comment.
        ///
        /// - Parameters:
        ///     - range: the range to apply the style to.
        ///     - comment: the comment to be stored.
        ///
        func replace(_ range: NSRange, withComment comment: String) {
            performAsyncUndoable { [weak self] in
                self?.replaceSynchronously(range, withComment: comment)
            }
        }

        private func replaceSynchronously(_ range: NSRange, withComment comment: String) {
            let descriptor = CommentNodeDescriptor(comment: comment)

            rootNode.replaceCharacters(in: range, with: descriptor)
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
        fileprivate func applyElement(_ elementType: StandardElementType, spanning range: NSRange, attributes: [Attribute] = []) {
            applyElement(elementType.rawValue, spanning: range, equivalentElementNames: elementType.equivalentNames, attributes: attributes)
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
        fileprivate func applyElement(_ elementName: String, spanning range: NSRange, equivalentElementNames: [String], attributes: [Attribute] = []) {
            
            let elementDescriptor = ElementNodeDescriptor(name: elementName, attributes: attributes, matchingNames: equivalentElementNames)
            applyElementDescriptor(elementDescriptor, spanning: range)
        }

        private func applyElementDescriptor(_ elementDescriptor: ElementNodeDescriptor, spanning range: NSRange) {
            domEditor.wrapChildren(intersectingRange: range, inElement: elementDescriptor)
        }
        
        // MARK: - Candidates for removal
        
        func updateImage(spanning ranges: [NSRange], url: URL, size: ImageAttachment.Size, alignment: ImageAttachment.Alignment) {
            performAsyncUndoable { [weak self] in
                self?.updateImageSynchronously(spanning: ranges, url: url, size: size, alignment: alignment)
            }
        }
        
        // MARK: - Candidates for removal: Synchronously
        
        private func updateImageSynchronously(spanning ranges: [NSRange], url: URL, size: ImageAttachment.Size, alignment: ImageAttachment.Alignment) {
            
            for range in ranges {
                let element = self.rootNode.lowestElementNodeWrapping(range)
                
                if element.name == StandardElementType.img.rawValue {
                    var components = [String]()
                    if let currentAttributes = element.valueForStringAttribute(named: "class") {
                        components = currentAttributes.components(separatedBy: CharacterSet.whitespaces)
                        components = components.filter({ (value) -> Bool in
                            return ImageAttachment.Alignment.fromHTML(string: value.lowercased()) == nil && ImageAttachment.Size.fromHTML(string: value.lowercased()) == nil
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
