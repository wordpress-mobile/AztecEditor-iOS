import Foundation
import UIKit

/// Composite view containing Aztec for visual editing and an HTML editor view.
///
public class EditorView: UIView {
    public let htmlTextView: UITextView
    public let richTextView: TextView
    public var htmlStorage: HTMLStorage {
        guard let htmlStorage = htmlTextView.textStorage as? HTMLStorage else {
            fatalError("If this happens, something is very off on the init config")
        }
        return htmlStorage
    }
    
    // MARK: - Encoding / Decoding
    
    static let htmlTextViewKey = "Aztec.EditorView.htmlTextView"
    static let richTextViewKey = "Aztec.EditorView.richTextView"

    // MARK: - Content Insets
    
    public var contentInset: UIEdgeInsets {
        get {
            return activeView.contentInset
        }
        
        set {
            htmlTextView.contentInset = newValue
            richTextView.contentInset = newValue
        }
    }
    
    public var contentOffset: CGPoint {
        get {
            return activeView.contentOffset
        }
        
        set {
            htmlTextView.contentOffset = newValue
            richTextView.contentOffset = newValue
        }
    }
    
    public var scrollIndicatorInsets: UIEdgeInsets {
        get {
            return activeView.scrollIndicatorInsets
        }
        
        set {
            htmlTextView.scrollIndicatorInsets = newValue
            richTextView.scrollIndicatorInsets = newValue
        }
    }
    
    // MARK: - Editing Mode
    
    public enum EditMode {
        case richText
        case html
        
        mutating func toggle() {
            switch self {
            case .html:
                self = .richText
            case .richText:
                self = .html
            }
        }
    }
    
    fileprivate(set) public var editingMode: EditMode = .richText {
        didSet {
            self.endEditing(true)
            
            switch editingMode {
            case .html:
                let newText = richTextView.getHTML()
                
                if newText != htmlTextView.text {
                    let range = NSRange(location: 0, length: htmlTextView.text.utf16.count)
                    
                    htmlTextView.replace(range, with: newText)
                }
                
                htmlTextView.becomeFirstResponder()
            case .richText:
                richTextView.setHTMLUndoable(htmlTextView.text)                
                richTextView.becomeFirstResponder()
            }
            
            refreshSubviewsVisibility()
        }
    }
    
    public func toggleEditingMode() {
        editingMode.toggle()
    }
    
    // MARK: - Initializers
    
    public required init?(coder aDecoder: NSCoder) {
        guard let htmlTextView = aDecoder.decodeObject(forKey: EditorView.htmlTextViewKey) as? UITextView,
            let richTextView = aDecoder.decodeObject(forKey: EditorView.richTextViewKey) as? TextView else {
                return nil
        }
        
        self.htmlTextView = htmlTextView
        self.richTextView = richTextView
        
        if #available(iOS 11, *) {
            htmlTextView.smartInsertDeleteType = .no
            htmlTextView.smartDashesType = .no
            htmlTextView.smartQuotesType = .no
        }
        
        super.init(coder: aDecoder)
        
        initialSetup()
    }
    
    public init(defaultFont: UIFont, defaultHTMLFont: UIFont, defaultParagraphStyle: ParagraphStyle, defaultMissingImage: UIImage) {
        let storage = HTMLStorage(defaultFont: defaultHTMLFont)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)

        self.htmlTextView = UITextView(frame: .zero, textContainer: container)
        self.richTextView = TextView(defaultFont: defaultFont, defaultParagraphStyle: defaultParagraphStyle, defaultMissingImage: defaultMissingImage)
        
        if #available(iOS 11, *) {
            htmlTextView.smartInsertDeleteType = .no
            htmlTextView.smartDashesType = .no
            htmlTextView.smartQuotesType = .no
        }
        
        super.init(frame: .zero)
        
        initialSetup()
    }
    
    // MARK: - Initial Setup
    
    private func initialSetup() {
        initialSubviewsSetup()
    }
    
    // MARK: - Subview Visibility
    
    private func refreshSubviewsVisibility() {
        richTextView.isHidden = editingMode == .html
        htmlTextView.isHidden = editingMode == .richText
    }
    
    // MARK: - HTML
    
    public func getHTML() -> String {
        switch editingMode {
        case .html:
            return htmlTextView.text
        case .richText:
            return richTextView.getHTML()
        }
    }
    
    public func setHTML(_ html: String) {
        htmlTextView.text = html
        richTextView.setHTML(html)
    }

    public var activeView: UITextView {
        switch editingMode {
        case .html:
            return htmlTextView
        case .richText:
            return richTextView
        }
    }
}

// MARK: - UIResponder

extension EditorView {
    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        return activeView.becomeFirstResponder()
    }
}

// MARK: - UITextInput

extension EditorView: UITextInput {
    
    public func text(in range: UITextRange) -> String? {
        return activeView.text(in: range)
    }
    
    public func replace(_ range: UITextRange, withText text: String) {
        activeView.replace(range, withText: text)
    }
    
    public var markedTextRange: UITextRange? {
        return activeView.markedTextRange
    }
    
    public var markedTextStyle: [NSAttributedString.Key: Any]? {
        get {
            return activeView.markedTextStyle
        }
        
        set(markedTextStyle) {
            activeView.markedTextStyle = markedTextStyle
        }
    }
    
    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        activeView.setMarkedText(markedText, selectedRange: selectedRange)
    }
    
    public func unmarkText() {
        activeView.unmarkText()
    }
    
    public var beginningOfDocument: UITextPosition {
        return activeView.beginningOfDocument
    }
    
    public var endOfDocument: UITextPosition {
        return activeView.endOfDocument
    }
    
    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        return activeView.textRange(from: fromPosition, to: toPosition)
    }
    
    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        return activeView.position(from: position, offset: offset)
    }
    
    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        return activeView.position(from: position, in: direction, offset: offset)
    }
    
    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        return activeView.compare(position, to: other)
    }
    
    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        return activeView.offset(from: from, to: toPosition)
    }
    
    public var inputDelegate: UITextInputDelegate? {
        get {
            return activeView.inputDelegate
        }
        
        set(inputDelegate) {
            activeView.inputDelegate = inputDelegate
        }
    }
    
    public var tokenizer: UITextInputTokenizer {
        return activeView.tokenizer
    }
    
    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        return activeView.position(within: range, farthestIn: direction)
    }
    
    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        return activeView.characterRange(byExtending: position, in: direction)
    }
    
    public func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> UITextWritingDirection {
        return activeView.baseWritingDirection(for: position, in: direction)
    }
    
    public func setBaseWritingDirection(_ writingDirection: UITextWritingDirection, for range: UITextRange) {
        activeView.setBaseWritingDirection(writingDirection, for: range)
    }
    
    public func firstRect(for range: UITextRange) -> CGRect {
        return activeView.firstRect(for: range)
    }
    
    public func caretRect(for position: UITextPosition) -> CGRect {
        return activeView.caretRect(for: position)
    }
    
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return activeView.selectionRects(for: range)
    }
    
    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        return activeView.closestPosition(to: point)
    }
    
    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        return activeView.closestPosition(to: point, within: range)
    }
    
    public func characterRange(at point: CGPoint) -> UITextRange? {
        return activeView.characterRange(at: point)
    }
    
    public var hasText: Bool {
        return activeView.hasText
    }
    
    public func insertText(_ text: String) {
        activeView.insertText(text)
    }
    
    public func deleteBackward() {
        activeView.deleteBackward()
    }
    
    public var selectedTextRange: UITextRange? {
        get {
            return activeView.selectedTextRange
        }
        
        set {
            activeView.selectedTextRange = newValue
        }
    }
}

// MARK: - Initial Setup

private extension EditorView {
    
    /// Performs the initial setup for the view.
    ///
    func initialSubviewsSetup() {
        addSubviews()
        setupConstraints()
        refreshSubviewsVisibility()
    }
    
    /// Adds the default subviews for the editor.
    ///
    private func addSubviews() {
        // This method should only be run once.  Running this more than once would mean something's off.
        assert(htmlTextView.superview == nil)
        assert(richTextView.superview == nil)
        
        self.addSubview(htmlTextView)
        self.addSubview(richTextView)
    }
    
    /// Sets-up the constraints for all subviews
    ///
    func setupConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        htmlTextView.translatesAutoresizingMaskIntoConstraints = false
        richTextView.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraints([
            NSLayoutConstraint(item: htmlTextView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: htmlTextView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: htmlTextView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: htmlTextView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0)
            ])
        
        addConstraints([
            NSLayoutConstraint(item: richTextView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: richTextView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: richTextView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: richTextView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0)
            ])
    }
}

// MARK: - Helper methods to set values on both views

public extension EditorView {

    var isScrollEnabled: Bool {
        set {
            htmlTextView.isScrollEnabled = newValue
            richTextView.isScrollEnabled = newValue
        }
        get {
            return activeView.isScrollEnabled
        }
    }
}
