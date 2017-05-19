import Foundation
import Aztec
import Gridicons
import Photos
import UIKit
import MobileCoreServices
import AVFoundation
import AVKit

class EditorDemoController: UIViewController {

    fileprivate var mediaErrorMode = false

    fileprivate(set) lazy var richTextView: Aztec.TextView = {
        let textView = Aztec.TextView(defaultFont: Constants.defaultContentFont, defaultMissingImage: Constants.defaultMissingImage)

        let toolbar = self.createToolbar(htmlMode: false)

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, using: toolbar, accessibilityLabel: accessibilityLabel)

        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.accessibilityIdentifier = "richContentView"

        return textView
    }()

    fileprivate(set) lazy var htmlTextView: UITextView = {
        let storage = HTMLStorage(defaultFont: Constants.defaultContentFont)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)

        let textView = UITextView(frame: .zero, textContainer: container)

        let toolbar = self.createToolbar(htmlMode: true)

        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        self.configureDefaultProperties(for: textView, using: toolbar, accessibilityLabel: accessibilityLabel)

        textView.isHidden = true
        textView.delegate = self
        textView.accessibilityIdentifier = "HTMLContentView"
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none

        return textView
    }()

    fileprivate(set) lazy var titleTextField: UITextView = {        
        let textField = UITextView()

        textField.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textField.delegate = self
        textField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        textField.returnKeyType = .next
        textField.textColor = UIColor.darkText
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isScrollEnabled = false
        textField.backgroundColor = .clear
        let toolbar = self.createToolbar(htmlMode: false)
        toolbar.enabled = false
        textField.inputAccessoryView = toolbar

        return textField
    }()

    fileprivate(set) lazy var titlePlaceholderLabel: UILabel = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Label for the title of the post field. Should be the same as WP core.")
        let textField = UILabel()

        textField.attributedText = NSAttributedString(string: placeholderText,
                                                      attributes: [NSForegroundColorAttributeName: UIColor.lightGray, NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)])
        textField.sizeToFit()
        textField.translatesAutoresizingMaskIntoConstraints = false

        return textField
    }()

    fileprivate var titleHeightConstraint: NSLayoutConstraint!
    fileprivate var titleTopConstraint: NSLayoutConstraint!

    fileprivate(set) lazy var separatorView: UIView = {
        let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        separatorView.backgroundColor = UIColor.darkText
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        return separatorView
    }()

    fileprivate(set) var editingMode: EditMode = .richText {
        didSet {
            view.endEditing(true)

            switch editingMode {
            case .html:
                htmlTextView.text = richTextView.getHTML(prettyPrint: true)
                htmlTextView.becomeFirstResponder()
            case .richText:
                setHTML(htmlTextView.text)                
                richTextView.becomeFirstResponder()
            }

            richTextView.isHidden = editingMode == .html
            htmlTextView.isHidden = editingMode == .richText
        }
    }    

    fileprivate var currentSelectedAttachment: ImageAttachment?

    fileprivate var formatBarAnimatedPeek = false

    var loadSampleHTML = false

    fileprivate var shortcodeProcessors = [ShortcodeProcessor]()

    func setHTML(_ html: String) {
        var processedHTML = html
        for shortcodeProcessor in shortcodeProcessors {
            processedHTML = shortcodeProcessor.process(text: processedHTML)
        }
        richTextView.setHTML(processedHTML)
    }


    // MARK: - Lifecycle Methods

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = UIRectEdge()
        navigationController?.navigationBar.isTranslucent = false


        view.backgroundColor = .white
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)
        view.addSubview(titleTextField)
        view.addSubview(titlePlaceholderLabel)
        view.addSubview(separatorView)
        configureConstraints()
        registerAttachmentImageProviders()
        registerShortcodeProcessors()

        let html: String

        if loadSampleHTML {
            html = getSampleHTML()
        } else {
            html = ""
        }

        setHTML(html)

        MediaAttachment.appearance.progressColor = UIColor.blue
        MediaAttachment.appearance.progressBackgroundColor = UIColor.lightGray
        MediaAttachment.appearance.progressHeight = 2.0
        MediaAttachment.appearance.overlayColor = UIColor(white: 0.5, alpha: 0.5)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidShow), name: .UIKeyboardDidShow, object: nil)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let nc = NotificationCenter.default
        nc.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        nc.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        nc.removeObserver(self, name: .UIKeyboardDidShow, object: nil)
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }

    // MARK: - Title and Title placeholder position methods
    func updateTitlePosition() {
        let referenceView: UIScrollView = editingMode == .richText ? richTextView : htmlTextView
        titleTopConstraint.constant = -(referenceView.contentOffset.y+referenceView.contentInset.top)

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset
    }
    
    func updateTitleHeight() {
        let referenceView: UIScrollView = editingMode == .richText ? richTextView : htmlTextView

        let sizeThatShouldFitTheContent = titleTextField.sizeThatFits(CGSize(width:view.frame.width - ( 2 * Constants.margin), height: CGFloat.greatestFiniteMagnitude))
        let insets = titleTextField.textContainerInset
        titleHeightConstraint.constant = max(sizeThatShouldFitTheContent.height, titleTextField.font!.lineHeight + insets.top + insets.bottom)

        var contentInset = referenceView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        referenceView.contentInset = contentInset
        referenceView.setContentOffset(CGPoint(x:0, y: -contentInset.top), animated: false)
    }

    func updateTitlePlaceholderVisibility() {
        self.titlePlaceholderLabel.isHidden = !titleTextField.text.isEmpty
    }

    // MARK: - Configuration Methods

    private func configureConstraints() {

        titleHeightConstraint = titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
        titleTopConstraint = titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: -richTextView.contentOffset.y)
        updateTitleHeight()
        NSLayoutConstraint.activate([
            titleTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.margin),
            titleTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -Constants.margin),
            titleTopConstraint,
            titleHeightConstraint
            ])

        let insets = titleTextField.textContainerInset
        NSLayoutConstraint.activate([
            titlePlaceholderLabel.leftAnchor.constraint(equalTo: titleTextField.leftAnchor, constant: insets.left + titleTextField.textContainer.lineFragmentPadding),
            titlePlaceholderLabel.rightAnchor.constraint(equalTo: titleTextField.rightAnchor, constant: -insets.right),
            titlePlaceholderLabel.topAnchor.constraint(equalTo: titleTextField.topAnchor, constant: insets.top),
            titlePlaceholderLabel.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
            ])

        NSLayoutConstraint.activate([
            separatorView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.margin),
            separatorView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -Constants.margin),
            separatorView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 0),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activate([
            richTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.margin),
            richTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -Constants.margin),
            richTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            richTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.margin)
            ])

        NSLayoutConstraint.activate([
            htmlTextView.leftAnchor.constraint(equalTo: richTextView.leftAnchor),
            htmlTextView.rightAnchor.constraint(equalTo: richTextView.rightAnchor),
            htmlTextView.topAnchor.constraint(equalTo: richTextView.topAnchor),
            htmlTextView.bottomAnchor.constraint(equalTo: richTextView.bottomAnchor),
            ])
    }


    private func configureDefaultProperties(for textView: UITextView, using formatBar: Aztec.FormatBar, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.font = Constants.defaultContentFont
        textView.inputAccessoryView = formatBar
        textView.keyboardDismissMode = .interactive
        textView.textColor = UIColor.darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func registerAttachmentImageProviders() {
        let providers: [TextViewAttachmentImageProvider] = [
            MoreAttachmentRenderer(),
            CommentAttachmentRenderer(font: Constants.defaultContentFont),
            HTMLAttachmentRenderer(font: Constants.defaultHtmlFont)
        ]

        for provider in providers {
            richTextView.registerAttachmentImageProvider(provider)
        }
    }

    private func registerShortcodeProcessors() {
        let videoPressProcessor = ShortcodeProcessor(tag:"wpvideo", replacer: { (shortcode) in
            var html = "<video "
            if let src = shortcode.attributes.unamedAttributes.first {
                html += "src=\"videopress://\(src)\" "
            }
            if let width = shortcode.attributes.namedAttributes["w"] {
                html += "width=\(width) "
            }
            if let height = shortcode.attributes.namedAttributes["h"] {
                html += "height=\(height) "
            }
            html += "\\>"
            return html
        })

        let wordPressVideoProcessor = ShortcodeProcessor(tag:"video", replacer: { (shortcode) in
            var html = "<video "
            if let src = shortcode.attributes.namedAttributes["src"] {
                html += "src=\"\(src)\" "
            }
            if let poster = shortcode.attributes.namedAttributes["poster"] {
                html += "poster=\"\(poster)\" "
            }
            html += "\\>"
            return html
        })
        
        shortcodeProcessors.append(videoPressProcessor)
        shortcodeProcessors.append(wordPressVideoProcessor)
    }


    // MARK: - Helpers

    @IBAction func toggleEditingMode() {
        editingMode.toggle()
    }


    // MARK: - Keyboard Handling

    func keyboardWillShow(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    func keyboardWillHide(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    func keyboardDidShow(_ notification: Notification) {
        guard richTextView.isFirstResponder, !formatBarAnimatedPeek else {
            return
        }

        let formatBar = richTextView.inputAccessoryView as? FormatBar
        formatBar?.animateSlightPeekWhenOverflows()
        formatBarAnimatedPeek = true
    }

    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        let referenceView: UIScrollView = editingMode == .richText ? richTextView : htmlTextView

        let scrollInsets = UIEdgeInsets(top: referenceView.scrollIndicatorInsets.top, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)
        let contentInset = UIEdgeInsets(top: referenceView.contentInset.top, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)

        htmlTextView.scrollIndicatorInsets = scrollInsets
        htmlTextView.contentInset = contentInset

        richTextView.scrollIndicatorInsets = scrollInsets
        richTextView.contentInset = contentInset
    }


    func updateFormatBar() {
        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }
        var identifiers = [FormattingIdentifier]()
        if (richTextView.selectedRange.length > 0) {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }
        // Filter multiple header identifier to single header identifier
        identifiers = identifiers.map({ (identifier) -> FormattingIdentifier in
            switch identifier {
            case .header1, .header2, .header3, .header4, .header5, .header6:
                return .header
            default:
                return identifier
            }
        })
        toolbar.selectItemsMatchingIdentifiers(identifiers)
    }


    // MARK: - Sample Content

    func getSampleHTML() -> String {
        let htmlFilePath = Bundle.main.path(forResource: "content", ofType: "html")!
        let fileContents: String

        do {
            fileContents = try String(contentsOfFile: htmlFilePath)
        } catch {
            fatalError("Could not load the sample HTML.  Check the file exists in the target and that it has the correct name.")
        }

        return fileContents
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        richTextView.inputAccessoryView = createToolbar(htmlMode: false)
        if richTextView.resignFirstResponder() {
            richTextView.becomeFirstResponder()
        }
        htmlTextView.inputAccessoryView = createToolbar(htmlMode: true)
        if htmlTextView.resignFirstResponder() {
            htmlTextView.becomeFirstResponder()
        }
        titleTextField.inputAccessoryView = createToolbar(htmlMode: true)
        if titleTextField.resignFirstResponder() {
            titleTextField.becomeFirstResponder()
        }

    }
}

extension EditorDemoController : UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        updateFormatBar()
        changeRichTextInputView(to: nil)
    }

    func textViewDidChange(_ textView: UITextView) {
        switch textView {
        case titleTextField:
            updateTitleHeight()
            updateTitlePlaceholderVisibility()
        default:
            break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTitlePosition()
    }
}

extension EditorDemoController : Aztec.TextViewFormattingDelegate {
    func textViewCommandToggledAStyle() {
        updateFormatBar()
    }
}


extension EditorDemoController : UITextFieldDelegate {

}

extension EditorDemoController {
    enum EditMode {
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
}


extension EditorDemoController : Aztec.FormatBarDelegate {
    func handleActionForIdentifier(_ identifier: FormattingIdentifier) {
        switch identifier {
        case .bold:
            toggleBold()
        case .italic:
            toggleItalic()
        case .underline:
            toggleUnderline()
        case .strikethrough:
            toggleStrikethrough()
        case .blockquote:
            toggleBlockquote()
        case .unorderedlist:
            toggleUnorderedList()
        case .orderedlist:
            toggleOrderedList()
        case .link:
            toggleLink()
        case .media:
            showImagePicker()
        case .sourcecode:
            toggleEditingMode()
        case .header, .header1, .header2, .header3, .header4, .header5, .header6:
            toggleHeader()
        case .more:
            insertMoreAttachment()
        case .horizontalruler:
            insertHorizontalRuler()
        case .p:
            break
        }

        updateFormatBar()
    }

    func toggleBold() {
        richTextView.toggleBold(range: richTextView.selectedRange)
    }


    func toggleItalic() {
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }


    func toggleUnderline() {
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }


    func toggleStrikethrough() {
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }


    func toggleOrderedList() {
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }


    func toggleUnorderedList() {
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }


    func toggleBlockquote() {
        richTextView.toggleBlockquote(range: richTextView.selectedRange)
    }

    func insertHorizontalRuler() {
        richTextView.replaceRangeWithHorizontalRuler(richTextView.selectedRange)
    }

    func toggleHeader() {
        // check if we already showing a custom view.
        if richTextView.inputView != nil {
            changeRichTextInputView(to: nil)
            return
        }
        let headerOptions = Constants.headers.map { (headerType) -> NSAttributedString in
            NSAttributedString(string: headerType.description, attributes:[NSFontAttributeName: UIFont.systemFont(ofSize: headerType.fontSize)])
        }

        let headerPicker = OptionsTableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 200), options: headerOptions)
        headerPicker.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        headerPicker.onSelect = { selected in
            self.richTextView.toggleHeader(Constants.headers[selected], range: self.richTextView.selectedRange)
            self.changeRichTextInputView(to: nil)
        }
        if let selectedHeader = Constants.headers.index(of: self.headerLevelForSelectedText()) {
            headerPicker.selectRow(at: IndexPath(row: selectedHeader, section: 0), animated: false, scrollPosition: .top)
        }
        changeRichTextInputView(to: headerPicker)
    }

    func changeRichTextInputView(to: UIView?) {
        if richTextView.inputView == to {
            return
        }
        richTextView.resignFirstResponder()
        richTextView.inputView = to
        richTextView.becomeFirstResponder()
    }

    func headerLevelForSelectedText() -> HeaderFormatter.HeaderType {
        var identifiers = [FormattingIdentifier]()
        if (richTextView.selectedRange.length > 0) {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: HeaderFormatter.HeaderType] = [
            .header1 : .h1,
            .header2 : .h2,
            .header3 : .h3,
            .header4 : .h4,
            .header5 : .h5,
            .header6 : .h6,
        ]
        for (key,value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }
        return .none
    }

    func toggleLink() {
        var linkTitle = ""
        var linkURL: URL? = nil
        var linkRange = richTextView.selectedRange
        // Let's check if the current range already has a link assigned to it.
        if let expandedRange = richTextView.linkFullRange(forRange: richTextView.selectedRange) {
           linkRange = expandedRange
           linkURL = richTextView.linkURL(forRange: expandedRange)
        }

        linkTitle = richTextView.attributedText.attributedSubstring(from: linkRange).string
        showLinkDialog(forURL: linkURL, title: linkTitle, range: linkRange)
    }

    func insertMoreAttachment() {
        richTextView.replaceRangeWithCommentAttachment(richTextView.selectedRange, text: Constants.moreAttachmentText)
    }

    func showLinkDialog(forURL url: URL?, title: String?, range: NSRange) {

        let isInsertingNewLink = (url == nil)
        var urlToUse = url

        if isInsertingNewLink {
            let pasteboard = UIPasteboard.general
            if let pastedURL = pasteboard.value(forPasteboardType:String(kUTTypeURL)) as? URL {
                urlToUse = pastedURL
            }
        }

        let insertButtonTitle = isInsertingNewLink ? NSLocalizedString("Insert Link", comment:"Label action for inserting a link on the editor") : NSLocalizedString("Update Link", comment:"Label action for updating a link on the editor")
        let removeButtonTitle = NSLocalizedString("Remove Link", comment:"Label action for removing a link from the editor");
        let cancelButtonTitle = NSLocalizedString("Cancel", comment:"Cancel button")

        let alertController = UIAlertController(title:insertButtonTitle,
                                                message:nil,
                                                preferredStyle:UIAlertControllerStyle.alert)

        alertController.addTextField(configurationHandler: { [weak self]textField in
            textField.clearButtonMode = UITextFieldViewMode.always;
            textField.placeholder = NSLocalizedString("URL", comment:"URL text field placeholder");

            textField.text = urlToUse?.absoluteString

            textField.addTarget(self,
                action:#selector(EditorDemoController.alertTextFieldDidChange),
            for:UIControlEvents.editingChanged)
            })

        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = UITextFieldViewMode.always
            textField.placeholder = NSLocalizedString("Link Name", comment:"Link name field placeholder")
            textField.isSecureTextEntry = false
            textField.autocapitalizationType = UITextAutocapitalizationType.sentences
            textField.autocorrectionType = UITextAutocorrectionType.default
            textField.spellCheckingType = UITextSpellCheckingType.default

            textField.text = title;

            })

        let insertAction = UIAlertAction(title:insertButtonTitle,
                                         style:UIAlertActionStyle.default,
                                         handler:{ [weak self]action in

                                            self?.richTextView.becomeFirstResponder()
                                            let linkURLString = alertController.textFields?.first?.text
                                            var linkTitle = alertController.textFields?.last?.text

                                            if  linkTitle == nil  || linkTitle!.isEmpty {
                                                linkTitle = linkURLString
                                            }

                                            guard
                                                let urlString = linkURLString,
                                                let url = URL(string:urlString),
                                                let title = linkTitle
                                                else {
                                                    return
                                            }
                                            self?.richTextView.setLink(url, title:title, inRange: range)
                                            })

        let removeAction = UIAlertAction(title:removeButtonTitle,
                                         style:UIAlertActionStyle.destructive,
                                         handler:{ [weak self] action in
                                            self?.richTextView.becomeFirstResponder()
                                            self?.richTextView.removeLink(inRange: range)
            })

        let cancelAction = UIAlertAction(title: cancelButtonTitle,
                                         style:UIAlertActionStyle.cancel,
                                         handler:{ [weak self]action in
                self?.richTextView.becomeFirstResponder()
            })

        alertController.addAction(insertAction)
        if !isInsertingNewLink {
            alertController.addAction(removeAction)
        }
            alertController.addAction(cancelAction)

        // Disabled until url is entered into field
        if let text = alertController.textFields?.first?.text {
            insertAction.isEnabled = !text.isEmpty
        }

        self.present(alertController, animated:true, completion:nil)
    }

    func alertTextFieldDidChange(_ textField: UITextField) {
        guard
            let alertController = presentedViewController as? UIAlertController,
            let urlFieldText = alertController.textFields?.first?.text,
            let insertAction = alertController.actions.first
            else {
            return
        }

        insertAction.isEnabled = !urlFieldText.isEmpty
    }


    func showImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
        picker.delegate = self
        picker.allowsEditing = false
        picker.navigationBar.isTranslucent = false
        picker.modalPresentationStyle = .currentContext

        present(picker, animated: true, completion: nil)
    }

    // MARK: -

    func makeToolbarButton(identifier: FormattingIdentifier) -> FormatBarItem {
        let button = FormatBarItem(image: identifier.iconImage, identifier: identifier)
        button.accessibilityLabel = identifier.accessibilityLabel
        button.accessibilityIdentifier = identifier.accessibilityIdentifier
        return button
    }

    func createToolbar(htmlMode: Bool) -> Aztec.FormatBar {

        let scrollableItems = scrollableItemsForToolbar
        let fixedItems = fixedItemsForToolbar

        let toolbar = Aztec.FormatBar()

        if htmlMode {
            let merged = scrollableItems + fixedItems
            for item in merged {
                item.isEnabled = false
                if item.identifier == .sourcecode {
                    item.isEnabled = true
                }
            }
        }

        toolbar.scrollableItems = scrollableItems
        toolbar.fixedItems = fixedItems
        toolbar.tintColor = .gray
        toolbar.highlightedTintColor = .blue
        toolbar.selectedTintColor = .darkGray
        toolbar.disabledTintColor = .lightGray
        toolbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0)
        toolbar.formatter = self

        return toolbar
    }

    var scrollableItemsForToolbar: [FormatBarItem] {
        return [
            makeToolbarButton(identifier: .media),
            makeToolbarButton(identifier: .header),
            makeToolbarButton(identifier: .bold),
            makeToolbarButton(identifier: .italic),
            makeToolbarButton(identifier: .underline),
            makeToolbarButton(identifier: .strikethrough),
            makeToolbarButton(identifier: .blockquote),
            makeToolbarButton(identifier: .unorderedlist),
            makeToolbarButton(identifier: .orderedlist),
            makeToolbarButton(identifier: .link),
            makeToolbarButton(identifier: .horizontalruler),
            makeToolbarButton(identifier: .more)
        ]
    }

    var fixedItemsForToolbar: [FormatBarItem] {
        return [
            makeToolbarButton(identifier: .sourcecode)
        ]
    }

}


extension EditorDemoController: TextViewAttachmentDelegate {

    func textView(_ textView: TextView, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping (Void) -> Void) -> UIImage {

        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, urlResponse, error) in
            DispatchQueue.main.async(execute: {
                    guard
                        error == nil,
                        let data = data,
                        let image = UIImage(data: data, scale:UIScreen.main.scale)
                    else {
                        failure()
                        return
                    }
                    success(image)
            })
        }) 
        task.resume()

        return Gridicon.iconOfType(.image)
    }
    
    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL {
        
        // TODO: start fake upload process
        if let image = imageAttachment.image {
            return saveToDisk(image: image)
        } else {
            return URL(string: "placeholder://")!
        }
    }

    func textView(_ textView: TextView, deletedAttachmentWith attachmentID: String) {
        print("Attachment \(attachmentID) removed.\n")
    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        switch attachment {
        case let attachment as HTMLAttachment:
            displayUnknownHtmlEditor(for: attachment)
        case let attachment as ImageAttachment:
            selected(textAttachment: attachment, atPosition: position)
        case let attachment as VideoAttachment:
            if let imageAttachment = currentSelectedAttachment {
                deselected(textAttachment: imageAttachment, atPosition: position)
            }
            selected(videoAttachment: attachment, atPosition: position)
        default:
            break
        }
    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        deselected(textAttachment: attachment, atPosition: position)
    }

    func selected(textAttachment attachment: ImageAttachment, atPosition position: CGPoint) {
        if (currentSelectedAttachment == attachment) {
            displayActions(forAttachment: attachment, position: position)
        } else {
            if let selectedAttachment = currentSelectedAttachment {
                selectedAttachment.clearAllOverlays()
                richTextView.refreshLayout(for: selectedAttachment)
            }

            // and mark the newly tapped attachment
            let message = NSLocalizedString("Tap to edit\n And change options", comment: "Options to show when tapping on a image on the post/page editor.")
            attachment.message = NSAttributedString(string: message, attributes: mediaMessageAttributes)
            attachment.overlayImage = Gridicon.iconOfType(.pencil).withRenderingMode(.alwaysTemplate)
            richTextView.refreshLayout(for: attachment)
            currentSelectedAttachment = attachment
        }
    }

    func deselected(textAttachment attachment: NSTextAttachment, atPosition position: CGPoint) {
        currentSelectedAttachment = nil
        if let mediaAttachment = attachment as? MediaAttachment {
            mediaAttachment.clearAllOverlays()
            richTextView.refreshLayout(for: mediaAttachment)
        }
    }

    func selected(videoAttachment attachment: VideoAttachment, atPosition position: CGPoint) {
        guard let videoURL = attachment.srcURL else {
            return
        }
        displayVideoPlayer(for: videoURL)
    }

    func displayVideoPlayer(for videoURL: URL) {
        let asset = AVURLAsset(url: videoURL)
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        controller.showsPlaybackControls = true
        controller.player = player
        player.play()
        present(controller, animated:true, completion: nil)
    }
}

extension EditorDemoController: UINavigationControllerDelegate
{
}

// MARK: - UIImagePickerControllerDelegate

extension EditorDemoController: UIImagePickerControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        richTextView.becomeFirstResponder()
        guard let mediaType =  info[UIImagePickerControllerMediaType] as? String else {
            return
        }
        let typeImage = kUTTypeImage as String
        let typeMovie = kUTTypeMovie as String

        switch mediaType {
        case typeImage:
            guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                return
            }

            // Insert Image + Reclaim Focus
            insertImage(image)

        case typeMovie:
            guard let videoURL = info[UIImagePickerControllerMediaURL] as? URL else {
                return
            }
            insertVideo(videoURL)
        default:
            print("Media type not supported: \(mediaType)")
        }
    }
}


// MARK: - Unknown HTML
//
private extension EditorDemoController {

    func displayUnknownHtmlEditor(for attachment: HTMLAttachment) {
        let targetVC = UnknownEditorViewController(attachment: attachment)
        targetVC.onDidSave = { [weak self] html in
            self?.richTextView.update(attachment: attachment, html: html)
            self?.dismiss(animated: true, completion: nil)
        }

        targetVC.onDidCancel = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        let navigationController = UINavigationController(rootViewController: targetVC)
        displayAsPopover(viewController: navigationController)
    }

    func displayAsPopover(viewController: UIViewController) {
        viewController.modalPresentationStyle = .popover
        viewController.preferredContentSize = view.frame.size

        let presentationController = viewController.popoverPresentationController
        presentationController?.sourceView = view
        presentationController?.delegate = self

        present(viewController, animated: true, completion: nil)
    }
}


// MARK: - UIPopoverPresentationControllerDelegate
//
extension EditorDemoController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}


// MARK: - Misc
//
private extension EditorDemoController
{
    func saveToDisk(image: UIImage) -> URL {
        let fileName = "\(ProcessInfo.processInfo.globallyUniqueString)_file.jpg"

        guard let data = UIImageJPEGRepresentation(image, 0.9) else {
            fatalError("Could not conert image to JPEG.")
        }

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        guard (try? data.write(to: fileURL, options: [.atomic])) != nil else {
            fatalError("Could not write the image to disk.")
        }
        
        return fileURL
    }
    
    func insertImage(_ image: UIImage) {
        
        let index = richTextView.positionForCursor()
        let fileURL = saveToDisk(image: image)
        
        let attachment = richTextView.insertImage(sourceURL: fileURL, atPosition: index, placeHolderImage: image)
        let imageID = attachment.identifier
        let progress = Progress(parent: nil, userInfo: ["imageID": imageID])
        progress.totalUnitCount = 100
        
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(EditorDemoController.timerFireMethod(_:)), userInfo: progress, repeats: true)
    }

    func insertVideo(_ videoURL: URL) {

        let index = richTextView.positionForCursor()

        let asset = AVURLAsset(url: videoURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        guard let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil) else {
            return
        }
        let posterImage = UIImage(cgImage: cgImage)
        let posterURL = saveToDisk(image: posterImage)
        let attachment = richTextView.insertVideo(atLocation: index, sourceURL: videoURL, posterURL: posterURL, placeHolderImage: posterImage)
        let imageID = attachment.identifier
        let progress = Progress(parent: nil, userInfo: ["imageID": imageID])
        progress.totalUnitCount = 100

        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(EditorDemoController.timerFireMethod(_:)), userInfo: progress, repeats: true)
    }

    @objc func timerFireMethod(_ timer: Timer) {
        guard let progress = timer.userInfo as? Progress,
            let imageId = progress.userInfo[ProgressUserInfoKey("imageID")] as? String
        else {
                
            return
        }        
        progress.completedUnitCount += 1
        if let attachment = richTextView.attachment(withId: imageId) {
            attachment.progress = progress.fractionCompleted                        
            if mediaErrorMode && progress.fractionCompleted >= 0.25 {
                timer.invalidate()
                let message = NSAttributedString(string: "Upload failed!", attributes: mediaMessageAttributes)
                attachment.message = message
                attachment.overlayImage = Gridicon.iconOfType(.refresh)
            }
            if progress.fractionCompleted >= 1 {
                timer.invalidate()
                attachment.progress = nil
            }
            richTextView.refreshLayout(for: attachment)
        } else {
            timer.invalidate()
        }
    }

    var mediaMessageAttributes: [String: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let shadow = NSShadow()
        shadow.shadowOffset = CGSize(width: 1, height: 1)
        shadow.shadowColor = UIColor(white: 0, alpha: 0.6)
        let attributes: [String:Any] = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20),
                                        NSParagraphStyleAttributeName: paragraphStyle,
                                        NSForegroundColorAttributeName: UIColor.white,
                                        NSShadowAttributeName: shadow]
        return attributes
    }

    func displayActions(forAttachment attachment: ImageAttachment, position: CGPoint) {
        let mediaID = attachment.identifier
        let title: String = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        let message: String? = nil
        let alertController = UIAlertController(title: title, message:message, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "User action to dismiss media options."),
                                          style: .cancel,
                                          handler: { (action) in
                                            if attachment == self.currentSelectedAttachment {
                                                self.currentSelectedAttachment = nil
                                                attachment.clearAllOverlays()
                                                self.richTextView.refreshLayout(for: attachment)
                                            }
        })
        alertController.addAction(dismissAction)

        let removeAction = UIAlertAction(title: NSLocalizedString("Remove Media", comment: "User action to remove media."),
                                         style: .destructive,
                                         handler: { (action) in
                                            self.richTextView.remove(attachmentID: mediaID)
        })
        alertController.addAction(removeAction)

        let detailsAction = UIAlertAction(title:NSLocalizedString("Media Details", comment: "User action to remove media."),
                                          style: .default,
                                          handler: { (action) in
                                            self.displayDetailsForAttachment(attachment, position: position)
        })
        alertController.addAction(detailsAction)

        alertController.title = title
        alertController.message = message
        alertController.popoverPresentationController?.sourceView = richTextView
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: position, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        present(alertController, animated:true, completion: nil)
    }

    func displayDetailsForAttachment(_ attachment: ImageAttachment, position:CGPoint) {
        let detailsViewController = AttachmentDetailsViewController.controller()
        detailsViewController.attachment = attachment
        detailsViewController.onUpdate = { [weak self] (alignment, size, url) in

            guard let strongSelf = self else {
                return
            }
            strongSelf.richTextView.update(attachment: attachment,
                                           alignment: alignment,
                                           size: size,
                                           url: url)
        }

        let navigationController = UINavigationController(rootViewController: detailsViewController)        
        present(navigationController, animated: true, completion: nil)
    }
}


extension EditorDemoController {

    struct Constants {
        static let defaultContentFont   = UIFont.systemFont(ofSize: 14)
        static let defaultHtmlFont      = UIFont.systemFont(ofSize: 24)
        static let defaultMissingImage  = Gridicon.iconOfType(.image)
        static let headers              = [HeaderFormatter.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let margin               = CGFloat(20)
        static let moreAttachmentText   = "more"
    }
}

extension FormattingIdentifier {

    var iconImage: UIImage {

        switch(self) {
        case .media:
            return Gridicon.iconOfType(.addImage)
        case .header:
            return Gridicon.iconOfType(.heading)
        case .bold:
            return Gridicon.iconOfType(.bold)
        case .italic:
            return Gridicon.iconOfType(.italic)
        case .underline:
            return Gridicon.iconOfType(.underline)
        case .strikethrough:
            return Gridicon.iconOfType(.strikethrough)
        case .blockquote:
            return Gridicon.iconOfType(.quote)
        case .orderedlist:
            return Gridicon.iconOfType(.listOrdered)
        case .unorderedlist:
            return Gridicon.iconOfType(.listUnordered)
        case .link:
            return Gridicon.iconOfType(.link)
        case .horizontalruler:
            return Gridicon.iconOfType(.minusSmall)
        case .sourcecode:
            return Gridicon.iconOfType(.code)
        case .more:
            return Gridicon.iconOfType(.readMore)
        case .header1:
            return Gridicon.iconOfType(.heading)
        case .header2:
            return Gridicon.iconOfType(.heading)
        case .header3:
            return Gridicon.iconOfType(.heading)
        case .header4:
            return Gridicon.iconOfType(.heading)
        case .header5:
            return Gridicon.iconOfType(.heading)
        case .header6:
            return Gridicon.iconOfType(.heading)
        case .p:
            return Gridicon.iconOfType(.heading)
        }
    }

    var accessibilityIdentifier: String {
        switch(self) {
        case .media:
            return "formatToolbarInsertMedia"
        case .header:
            return "formatToolbarSelectParagraphStyle"
        case .bold:
            return "formatToolbarToggleBold"
        case .italic:
            return "formatToolbarToggleItalic"
        case .underline:
            return "formatToolbarToggleUnderline"
        case .strikethrough:
            return "formatToolbarToggleStrikethrough"
        case .blockquote:
            return "formatToolbarToggleBlockquote"
        case .orderedlist:
            return "formatToolbarToggleListOrdered"
        case .unorderedlist:
            return "formatToolbarToggleListUnordered"
        case .link:
            return "formatToolbarInsertLink"
        case .horizontalruler:
            return "formatToolbarInsertHorizontalRuler"
        case .sourcecode:
            return "formatToolbarToggleHtmlView"
        case .more:
            return "formatToolbarInsertMore"
        case .header1:
            return "formatToolbarToggleH1"
        case .header2:
            return "formatToolbarToggleH2"
        case .header3:
            return "formatToolbarToggleH3"
        case .header4:
            return "formatToolbarToggleH4"
        case .header5:
            return "formatToolbarToggleH5"
        case .header6:
            return "formatToolbarToggleH6"
        case .p:
            return "none"
        }
    }

    var accessibilityLabel: String {
        switch(self) {
        case .media:
            return NSLocalizedString("Insert media", comment: "Accessibility label for insert media button on formatting toolbar.")
        case .header:
            return NSLocalizedString("Select paragraph style", comment: "Accessibility label for selecting paragraph style button on formatting toolbar.")
        case .bold:
            return NSLocalizedString("Bold", comment: "Accessibility label for bold button on formatting toolbar.")
        case .italic:
            return NSLocalizedString("Italic", comment: "Accessibility label for italic button on formatting toolbar.")
        case .underline:
            return NSLocalizedString("Underline", comment: "Accessibility label for underline button on formatting toolbar.")
        case .strikethrough:
            return NSLocalizedString("Strike Through", comment: "Accessibility label for strikethrough button on formatting toolbar.")
        case .blockquote:
            return NSLocalizedString("Block Quote", comment: "Accessibility label for block quote button on formatting toolbar.")
        case .orderedlist:
            return NSLocalizedString("Ordered List", comment: "Accessibility label for Ordered list button on formatting toolbar.")
        case .unorderedlist:
            return NSLocalizedString("Unordered List", comment: "Accessibility label for unordered list button on formatting toolbar.")
        case .link:
            return NSLocalizedString("Insert Link", comment: "Accessibility label for insert link button on formatting toolbar.")
        case .horizontalruler:
            return NSLocalizedString("Insert Horizontal Ruler", comment: "Accessibility label for insert horizontal ruler button on formatting toolbar.")
        case .sourcecode:
            return NSLocalizedString("HTML", comment:"Accessibility label for HTML button on formatting toolbar.")
        case .more:
            return NSLocalizedString("More", comment:"Accessibility label for the More button on formatting toolbar.")
        case .header1:
            return NSLocalizedString("Header 1", comment: "Accessibility label for selecting h1 paragraph style button on the formatting toolbar.")
        case .header2:
            return NSLocalizedString("Header 2", comment: "Accessibility label for selecting h2 paragraph style button on the formatting toolbar.")
        case .header3:
            return NSLocalizedString("Header 3", comment: "Accessibility label for selecting h3 paragraph style button on the formatting toolbar.")
        case .header4:
            return NSLocalizedString("Header 4", comment: "Accessibility label for selecting h4 paragraph style button on the formatting toolbar.")
        case .header5:
            return NSLocalizedString("Header 5", comment: "Accessibility label for selecting h5 paragraph style button on the formatting toolbar.")
        case .header6:
            return NSLocalizedString("Header 6", comment: "Accessibility label for selecting h6 paragraph style button on the formatting toolbar.")
        case .p:
            return ""
        }
    }
}
