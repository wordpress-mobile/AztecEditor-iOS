import Foundation
import UIKit
import Aztec


class EditorDemoController: UIViewController
{
    private var bottomConstraint: NSLayoutConstraint?


    private (set) lazy var editor: AztecVisualEditor = {
        let e = AztecVisualEditor(textView: self.textView)
        return e
    }()


    private(set) lazy var textView: UITextView = {
        let tv = AztecVisualEditor.createTextView()
        let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

        tv.accessibilityLabel = NSLocalizedString("Content", comment: "Post content")
        tv.delegate = self
        tv.font = font
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.formatter = self
        tv.inputAccessoryView = toolbar
        tv.textColor = UIColor.darkTextColor()
        tv.translatesAutoresizingMaskIntoConstraints = false

        tv.addSubview(self.titleTextField)
        tv.addSubview(self.separatorView)

        return tv
    }()


    private(set) lazy var titleTextField: UITextField = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Label for the title of the post field. Should be the same as WP core.")
        let tf = UITextField()

        tf.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        tf.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                      attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        tf.autoresizingMask = [UIViewAutoresizing.FlexibleWidth]
        tf.delegate = self
        tf.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.enabled = false
        tf.inputAccessoryView = toolbar
        tf.returnKeyType = .Next
        tf.textColor = UIColor.darkTextColor()

        return tf
    }()


    private(set) lazy var separatorView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        v.autoresizingMask = [.FlexibleWidth]
        v.backgroundColor = UIColor.darkTextColor()

        return v
    }()


    var titleFont: UIFont? {
        get {
            return titleTextField.font
        }
        set {
            titleTextField.font = newValue
            layoutTextView()
        }
    }


    var titleColor: UIColor? {
        get {
            return titleTextField.textColor
        }
        set {
            titleTextField.textColor = newValue
        }
    }


    var bodyFont: UIFont? {
        get {
            return textView.font
        }
        set {
            textView.font = newValue
            layoutTextView()
        }
    }


    var bodyColor: UIColor? {
        get {
            return textView.textColor
        }
        set {
            textView.textColor = newValue
        }
    }


    var separatorColor: UIColor? {
        get {
            return separatorView.backgroundColor
        }
        set {
            separatorView.backgroundColor = newValue
        }
    }


    // MARK: - Lifecycle Methods


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // lazy load the editor
        _ = editor

        view.addSubview(textView)

        configureConstraints()
        layoutTextView()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }


    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }


    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        // TODO: Update toolbars
        //    [self.editorToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];
        //    [self.titleToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];

    }


    // MARK: - Configuration Methods


    func configureConstraints() {
        let views = [
            "textView" : textView
        ]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[textView]|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[textView]", options: [], metrics: nil, views: views))
        bottomConstraint = NSLayoutConstraint(item: textView,
                                              attribute: .Bottom,
                                              relatedBy: .Equal,
                                              toItem: view,
                                              attribute: .Bottom,
                                              multiplier: 1.0,
                                              constant: 0.0)
        view.addConstraint(bottomConstraint!)
    }


    // MARK: - Layout


    func layoutTextView() {
        let lineHeight = titleTextField.font!.lineHeight
        let offset: CGFloat = 15.0
        let width: CGFloat = textView.frame.width - (offset * 2)
        let height: CGFloat = lineHeight * 2.0
        titleTextField.frame = CGRect(x: offset, y: 0, width: width, height: height)

        separatorView.frame = CGRect(x: offset, y: titleTextField.frame.maxY, width: width, height: 1)

        let top: CGFloat = separatorView.frame.maxY + lineHeight
        textView.textContainerInset = UIEdgeInsets(top: top, left: offset, bottom: lineHeight, right: offset)
    }


    // MARK: - Keyboard Handling


    func keyboardWillShow(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(),
            let duration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
            else {
                return
        }
        bottomConstraint?.constant = -(view.frame.maxY - keyboardFrame.minY)
        UIView.animateWithDuration(duration) {
            self.view.layoutIfNeeded()
        }
    }


    func keyboardWillHide(notification: NSNotification) {
        bottomConstraint?.constant = 0
    }


    func updateFormatBar() {
        guard let toolbar = textView.inputAccessoryView as? AztecFormatBar else {
            return
        }

        let range = textView.selectedRange
        let identifiers = editor.formatIdentifiersSpanningRange(range)
        toolbar.selectItemsMatchingIdentifiers(identifiers)
    }

}


extension EditorDemoController : UITextViewDelegate
{
    func textViewDidChangeSelection(textView: UITextView) {
        updateFormatBar()
    }
}


extension EditorDemoController : UITextFieldDelegate
{

}


extension EditorDemoController : AztecFormatBarDelegate
{

    func handleActionForIdentifier(identifier: String) {
        switch identifier {
        case AztecFormattingIdentifier.Bold.rawValue :
            toggleBold()
            break
        case AztecFormattingIdentifier.Italic.rawValue :
            toggleItalic()
            break
        case AztecFormattingIdentifier.Underline.rawValue :
            toggleUnderline()
            break
        case AztecFormattingIdentifier.Strikethrough.rawValue :
            toggleStrikethrough()
            break
        case AztecFormattingIdentifier.Blockquote.rawValue :
            toggleBlockquote()
            break
        case AztecFormattingIdentifier.Unorderedlist.rawValue :
            toggleUnorderedList()
            break
        case AztecFormattingIdentifier.Orderedlist.rawValue :
            toggleOrderedList()
            break
        case AztecFormattingIdentifier.Link.rawValue :
            toggleLink()
            break
        case AztecFormattingIdentifier.Media.rawValue :
            insertImage()
            break;
        default:
            break
        }
        updateFormatBar()
    }

    func toggleBold() {
        editor.toggleBold(range: textView.selectedRange)
    }


    func toggleItalic() {
        editor.toggleItalic(range: textView.selectedRange)
    }


    func toggleUnderline() {
        editor.toggleUnderline(range: textView.selectedRange)
    }


    func toggleStrikethrough() {
        editor.toggleStrikethrough(range: textView.selectedRange)
    }


    func toggleOrderedList() {
        editor.toggleOrderedList(range: textView.selectedRange)
    }


    func toggleUnorderedList() {
        editor.toggleUnorderedList(range: textView.selectedRange)
    }


    func toggleBlockquote() {
        editor.toggleBlockquote(range: textView.selectedRange)
    }


    func toggleLink() {
        editor.toggleLink(range: textView.selectedRange, params: [String : AnyObject]())
    }


    func insertImage() {
        editor.insertImage(textView.selectedRange.location, params: [String : AnyObject]())
    }

    // MARK: -

    func createToolbar() -> AztecFormatBar {
        let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let items = [
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_media"), identifier: AztecFormattingIdentifier.Media.rawValue),
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_bold"), identifier: AztecFormattingIdentifier.Bold.rawValue),
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_italic"), identifier: AztecFormattingIdentifier.Italic.rawValue),
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_underline"), identifier: AztecFormattingIdentifier.Underline.rawValue),
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_strikethrough"), identifier: AztecFormattingIdentifier.Strikethrough.rawValue),
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_quote"), identifier: AztecFormattingIdentifier.Blockquote.rawValue),
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_ul"), identifier: AztecFormattingIdentifier.Unorderedlist.rawValue),
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_ol"), identifier: AztecFormattingIdentifier.Orderedlist.rawValue),
            flex,
            AztecFormatBarItem(image: templateImage(named:"icon_format_link"), identifier: AztecFormattingIdentifier.Link.rawValue),
            flex,
        ]

        let toolbar = AztecFormatBar()
        toolbar.tintColor = UIColor.grayColor()
        toolbar.highlightedTintColor = UIColor.blueColor()
        toolbar.selectedTintColor = UIColor.darkGrayColor()
        toolbar.disabledTintColor = UIColor.lightGrayColor()

        toolbar.items = items
        return toolbar
    }

    func templateImage(named named: String) -> UIImage {
        return UIImage(named: named)!.imageWithRenderingMode(.AlwaysTemplate)
    }

}
