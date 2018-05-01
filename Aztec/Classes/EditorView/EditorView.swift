import Foundation
import UIKit

/// Composite view containing Aztec for visual editing and an HTML editor view.
///
public class EditorView: UIView {
    public let htmlTextView: UITextView
    public let richTextView: TextView
    
    // MARK: - Encoding / Decoding
    static let htmlTextViewKey = "Aztec.EditorView.htmlTextView"
    static let richTextViewKey = "Aztec.EditorView.richTextView"
    
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
                htmlTextView.text = richTextView.getHTML()
                htmlTextView.becomeFirstResponder()
            case .richText:
                richTextView.setHTML(htmlTextView.text)
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
        return richTextView.getHTML()
    }
    
    public func setHTML(_ html: String) {
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
