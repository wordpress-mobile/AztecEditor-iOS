import Foundation
import UIKit
import Aztec
import Photos


class EditorDemoController: UIViewController
{
    static let margin = CGFloat(20)
    static let defaultContentFont = UIFont.systemFontOfSize(14)

    private (set) lazy var editor: AztecVisualEditor = {
        return AztecVisualEditor(textView: self.richTextView, defaultFont: self.dynamicType.defaultContentFont)
    }()


    private(set) lazy var richTextView: UITextView = {
        let tv = AztecVisualEditor.createTextView()

        tv.accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        tv.delegate = self
        tv.font = defaultContentFont
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.formatter = self
        tv.inputAccessoryView = toolbar
        tv.textColor = UIColor.darkTextColor()
        tv.translatesAutoresizingMaskIntoConstraints = false

        return tv
    }()

    private(set) lazy var htmlTextView: UITextView = {
        let tv = UITextView()

        tv.accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        tv.font = defaultContentFont
        tv.textColor = UIColor.darkTextColor()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.hidden = true

        return tv
    }()

    private(set) lazy var titleTextField: UITextField = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Label for the title of the post field. Should be the same as WP core.")
        let tf = UITextField()

        tf.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        tf.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                      attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        tf.delegate = self
        tf.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.enabled = false
        tf.inputAccessoryView = toolbar
        tf.returnKeyType = .Next
        tf.textColor = UIColor.darkTextColor()
        tf.translatesAutoresizingMaskIntoConstraints = false

        return tf
    }()

    private(set) lazy var separatorView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        v.backgroundColor = UIColor.darkTextColor()
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()

    private(set) var mode = EditionMode.RichText {
        didSet {
            switch mode {
            case .HTML:
                switchToHTML()
            case .RichText:
                switchToRichText()
            }
        }
    }

    var loadSampleHTML = false


    // MARK: - Lifecycle Methods

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // lazy load the editor
        _ = editor

        edgesForExtendedLayout = .None
        navigationController?.navigationBar.translucent = false

        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(titleTextField)
        view.addSubview(separatorView)
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)

        let html: String

        if loadSampleHTML {
            html = getSampleHTML()
        } else {
            html = ""
        }

        editor.setHTML(html)

        configureConstraints()
        configureNavigationBar()
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

        NSLayoutConstraint.activateConstraints([
            titleTextField.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: self.dynamicType.margin),
            titleTextField.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -self.dynamicType.margin),
            titleTextField.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: self.dynamicType.margin),
            titleTextField.heightAnchor.constraintEqualToConstant(titleTextField.font!.lineHeight)
            ])

        NSLayoutConstraint.activateConstraints([
            separatorView.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: self.dynamicType.margin),
            separatorView.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -self.dynamicType.margin),
            separatorView.topAnchor.constraintEqualToAnchor(titleTextField.bottomAnchor, constant: self.dynamicType.margin),
            separatorView.heightAnchor.constraintEqualToConstant(separatorView.frame.height)
            ])

        NSLayoutConstraint.activateConstraints([
            richTextView.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: self.dynamicType.margin),
            richTextView.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -self.dynamicType.margin),
            richTextView.topAnchor.constraintEqualToAnchor(separatorView.bottomAnchor, constant: self.dynamicType.margin),
            richTextView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -self.dynamicType.margin)
            ])

        NSLayoutConstraint.activateConstraints([
            htmlTextView.leftAnchor.constraintEqualToAnchor(richTextView.leftAnchor),
            htmlTextView.rightAnchor.constraintEqualToAnchor(richTextView.rightAnchor),
            htmlTextView.topAnchor.constraintEqualToAnchor(richTextView.topAnchor),
            htmlTextView.bottomAnchor.constraintEqualToAnchor(richTextView.bottomAnchor),
            ])
    }

    func configureNavigationBar() {
        let title = NSLocalizedString("HTML", comment: "HTML!")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: title,
                                                            style: .Plain,
                                                            target: self,
                                                           action: #selector(switchEditionMode))
    }


    // MARK: - Helpers

    @IBAction func switchEditionMode() {
        mode.toggle()
    }


    // MARK: - Keyboard Handling

    func keyboardWillShow(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
            else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }


    func keyboardWillHide(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue()
            else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    private func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        htmlTextView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)
        htmlTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)

        richTextView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)
        richTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)
    }


    func updateFormatBar() {
        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        let range = richTextView.selectedRange
        let identifiers = editor.formatIdentifiersSpanningRange(range)
        toolbar.selectItemsMatchingIdentifiers(identifiers)
    }


    // MARK: - Sample Content

    func getSampleHTML() -> String {
        let htmlFilePath = NSBundle.mainBundle().pathForResource("content", ofType: "html")!
        let fileContents: String

        do {
            fileContents = try String(contentsOfFile: htmlFilePath)
        } catch {
            fatalError("Could not load the sample HTML.  Check the file exists in the target and that it has the correct name.")
        }

        return fileContents
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

extension EditorDemoController
{
    enum EditionMode {
        case RichText
        case HTML

        mutating func toggle() {
            switch self {
            case .HTML:
                self = .RichText
            case .RichText:
                self = .HTML
            }
        }
    }

    private func switchToHTML() {
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("Native", comment: "Rich Edition!")

        htmlTextView.text = editor.getHTML()

        view.endEditing(true)
        htmlTextView.hidden = false
        richTextView.hidden = true
    }

    private func switchToRichText() {
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("HTML", comment: "HTML!")

        editor.setHTML(htmlTextView.text)

        view.endEditing(true)
        richTextView.hidden = false
        htmlTextView.hidden = true
    }
}


extension EditorDemoController : Aztec.FormatBarDelegate
{
    func handleActionForIdentifier(identifier: String) {
        guard let identifier = Aztec.FormattingIdentifier(rawValue: identifier) else {
            return
        }

        switch identifier {
        case .Bold:
            toggleBold()
        case .Italic:
            toggleItalic()
        case .Underline:
            toggleUnderline()
        case .Strikethrough:
            toggleStrikethrough()
        case .Blockquote:
            toggleBlockquote()
        case .Unorderedlist:
            toggleUnorderedList()
        case .Orderedlist:
            toggleOrderedList()
        case .Link:
            toggleLink()
        case .Media:
            showImagePicker()
        }
        updateFormatBar()
    }

    func toggleBold() {
        editor.toggleBold(range: richTextView.selectedRange)
    }


    func toggleItalic() {
        editor.toggleItalic(range: richTextView.selectedRange)
    }


    func toggleUnderline() {
        editor.toggleUnderline(range: richTextView.selectedRange)
    }


    func toggleStrikethrough() {
        editor.toggleStrikethrough(range: richTextView.selectedRange)
    }


    func toggleOrderedList() {
        editor.toggleOrderedList(range: richTextView.selectedRange)
    }


    func toggleUnorderedList() {
        editor.toggleUnorderedList(range: richTextView.selectedRange)
    }


    func toggleBlockquote() {
        editor.toggleBlockquote(range: richTextView.selectedRange)
    }


    func toggleLink() {
        editor.toggleLink(range: richTextView.selectedRange, params: [String : AnyObject]())
    }


    func showImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .PhotoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary) ?? []
        picker.delegate = self
        picker.allowsEditing = false
        picker.navigationBar.translucent = false
        picker.modalPresentationStyle = .CurrentContext

        presentViewController(picker, animated: true, completion: nil)
    }

    // MARK: -

    func createToolbar() -> Aztec.FormatBar {
        let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let items = [
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_media"), identifier: Aztec.FormattingIdentifier.Media.rawValue),
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_bold"), identifier: Aztec.FormattingIdentifier.Bold.rawValue),
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_italic"), identifier: Aztec.FormattingIdentifier.Italic.rawValue),
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_underline"), identifier: Aztec.FormattingIdentifier.Underline.rawValue),
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_strikethrough"), identifier: Aztec.FormattingIdentifier.Strikethrough.rawValue),
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_quote"), identifier: Aztec.FormattingIdentifier.Blockquote.rawValue),
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_ul"), identifier: Aztec.FormattingIdentifier.Unorderedlist.rawValue),
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_ol"), identifier: Aztec.FormattingIdentifier.Orderedlist.rawValue),
            flex,
            Aztec.FormatBarItem(image: templateImage(named:"icon_format_link"), identifier: Aztec.FormattingIdentifier.Link.rawValue),
            flex,
        ]

        let toolbar = Aztec.FormatBar()
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


extension EditorDemoController : UINavigationControllerDelegate
{

}


extension EditorDemoController : UIImagePickerControllerDelegate
{
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)

        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }

        // Insert Image + Reclaim Focus
        insertImage(image)
        richTextView.becomeFirstResponder()
    }
}


private extension EditorDemoController
{
    func insertImage(image: UIImage) {
        let index = richTextView.positionForCursor()
        editor.insertImage(image, index: index)
    }
}
