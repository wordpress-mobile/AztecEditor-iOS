import Foundation
import Aztec
import Gridicons
import Photos
import UIKit
import MobileCoreServices

class EditorDemoController: UIViewController {
    static let margin = CGFloat(20)
    static let defaultContentFont = UIFont.systemFont(ofSize: 14)

    fileprivate var mediaErrorMode = false

    lazy var headers: [HeaderFormatter.HeaderType] = [.none, .h1, .h2, .h3, .h4, .h5, .h6]

    fileprivate(set) lazy var richTextView: Aztec.TextView = {
        let defaultMissingImage = Gridicon.iconOfType(.image)
        let textView = Aztec.TextView(defaultFont: type(of: self).defaultContentFont, defaultMissingImage: defaultMissingImage)

        let toolbar = self.createToolbar(htmlMode: false)

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, using: toolbar, accessibilityLabel: accessibilityLabel)

        textView.delegate = self
        textView.formattingDelegate = self
        textView.mediaDelegate = self

        return textView
    }()

    fileprivate(set) lazy var htmlTextView: UITextView = {
        let textView = UITextView()

        let toolbar = self.createToolbar(htmlMode: true)

        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        self.configureDefaultProperties(for: textView, using: toolbar, accessibilityLabel: accessibilityLabel)

        textView.isHidden = true

        return textView
    }()

    fileprivate(set) lazy var titleTextField: UITextField = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Label for the title of the post field. Should be the same as WP core.")
        let textField = UITextField()

        textField.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                      attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        textField.delegate = self
        textField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        textField.returnKeyType = .next
        textField.textColor = UIColor.darkText
        textField.translatesAutoresizingMaskIntoConstraints = false

        let toolbar = self.createToolbar(htmlMode: false)
        toolbar.enabled = false
        textField.inputAccessoryView = toolbar

        return textField
    }()

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
                htmlTextView.text = richTextView.getHTML()
                htmlTextView.becomeFirstResponder()
            case .richText:
                richTextView.setHTML(htmlTextView.text)
                richTextView.becomeFirstResponder()
            }

            richTextView.isHidden = editingMode == .html
            htmlTextView.isHidden = editingMode == .richText
        }
    }    

    fileprivate var currentSelectedAttachment: TextAttachment?

    fileprivate var formatBarAnimatedPeek = false

    var loadSampleHTML = false


    // MARK: - Lifecycle Methods

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = UIRectEdge()
        navigationController?.navigationBar.isTranslucent = false

        view.backgroundColor = UIColor.white
        view.addSubview(titleTextField)
        view.addSubview(separatorView)
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)

        configureConstraints()

        let html: String

        if loadSampleHTML {
            html = getSampleHTML()
        } else {
            html = ""
        }

        richTextView.setHTML(html)

        TextAttachment.appearance.progressColor = UIColor.blue
        TextAttachment.appearance.progressBackgroundColor = UIColor.lightGray
        TextAttachment.appearance.progressHeight = 2.0
        TextAttachment.appearance.overlayColor = UIColor(white: 0.5, alpha: 0.5)
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
        // TODO: Update toolbars
        //    [self.editorToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];
        //    [self.titleToolbar configureForHorizontalSizeClass:newCollection.horizontalSizeClass];

    }


    // MARK: - Configuration Methods

    private func configureConstraints() {

        NSLayoutConstraint.activate([
            titleTextField.leftAnchor.constraint(equalTo: view.leftAnchor, constant: type(of: self).margin),
            titleTextField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -type(of: self).margin),
            titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: type(of: self).margin),
            titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
            ])

        NSLayoutConstraint.activate([
            separatorView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: type(of: self).margin),
            separatorView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -type(of: self).margin),
            separatorView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: type(of: self).margin),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activate([
            richTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: type(of: self).margin),
            richTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -type(of: self).margin),
            richTextView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: type(of: self).margin),
            richTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -type(of: self).margin)
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
        textView.font = EditorDemoController.defaultContentFont
        textView.inputAccessoryView = formatBar
        textView.keyboardDismissMode = .interactive
        textView.textColor = UIColor.darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
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
        let scrollInsets = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.frame.maxY - keyboardFrame.minY, right: 0)

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
        case .horizontalruler:
            insertHorizontalRuler()
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
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
    }

    func toggleHeader() {
        // check if we already showing a custom view.
        if richTextView.inputView != nil {
            changeRichTextInputView(to: nil)
            return
        }
        let headerOptions = headers.map { (headerType) -> NSAttributedString in
            NSAttributedString(string: headerType.description, attributes:[NSFontAttributeName: UIFont.systemFont(ofSize: headerType.fontSize)])
        }

        let headerPicker = OptionsTableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 200), options: headerOptions)
        headerPicker.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        headerPicker.onSelect = { selected in
            self.richTextView.toggleHeader(self.headers[selected], range: self.richTextView.selectedRange)
            self.changeRichTextInputView(to: nil)
        }
        if let selectedHeader = headers.index(of:self.headerLevelForSelectedText()) {
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
            FormatBarItem(image: Gridicon.iconOfType(.addImage), identifier: .media),
            FormatBarItem(image: Gridicon.iconOfType(.heading), identifier: .header),
            FormatBarItem(image: Gridicon.iconOfType(.bold), identifier: .bold),
            FormatBarItem(image: Gridicon.iconOfType(.italic), identifier: .italic),
            FormatBarItem(image: Gridicon.iconOfType(.underline), identifier: .underline),
            FormatBarItem(image: Gridicon.iconOfType(.strikethrough), identifier: .strikethrough),
            FormatBarItem(image: Gridicon.iconOfType(.quote), identifier: .blockquote),
            FormatBarItem(image: Gridicon.iconOfType(.listUnordered), identifier: .unorderedlist),
            FormatBarItem(image: Gridicon.iconOfType(.listOrdered), identifier: .orderedlist),
            FormatBarItem(image: Gridicon.iconOfType(.link), identifier: .link),
            FormatBarItem(image: Gridicon.iconOfType(.minusSmall), identifier: .horizontalruler)
        ]
    }

    var fixedItemsForToolbar: [FormatBarItem] {
        return [
            FormatBarItem(image: Gridicon.iconOfType(.code), identifier: .sourcecode)
        ]
    }

}

extension EditorDemoController: TextViewMediaDelegate
{
    func textView(_ textView: TextView, imageAtUrl url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping (Void) -> Void) -> UIImage {

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
    
    func textView(_ textView: TextView, urlForAttachment attachment: TextAttachment) -> URL {
        
        // TODO: start fake upload process
        if let image = attachment.image {
            return saveToDisk(image: image)
        } else {
            return URL(string: "placeholder://")!
        }
    }

    func textView(_ textView: TextView, deletedAttachmentWithID attachmentID: String) {
        print("Attachment \(attachmentID) removed.\n")
    }

    func textView(_ textView: TextView, selectedAttachment attachment: TextAttachment, atPosition position: CGPoint) {

        if (currentSelectedAttachment == attachment) {
            displayActions(forAttachment: attachment, position: position)
        } else {
            if let selectedAttachment = currentSelectedAttachment {
                selectedAttachment.clearAllOverlays()
                richTextView.refreshLayoutFor(attachment: selectedAttachment)
            }

            // and mark the newly tapped attachment
            let message = NSLocalizedString("Tap to edit\n And change options", comment: "Options to show when tapping on a image on the post/page editor.")
            attachment.message = NSAttributedString(string: message, attributes: mediaMessageAttributes)
            attachment.overlayImage = Gridicon.iconOfType(.pencil).withRenderingMode(.alwaysTemplate)
            richTextView.refreshLayoutFor(attachment: attachment)
            currentSelectedAttachment = attachment
        }
    }

    func textView(_ textView: TextView, deselectedAttachment attachment: TextAttachment, atPosition position: CGPoint) {
        attachment.clearAllOverlays()
        richTextView.refreshLayoutFor(attachment: attachment)
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

        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }

        // Insert Image + Reclaim Focus
        insertImage(image)
        richTextView.becomeFirstResponder()
    }
}

// MARK: - Misc

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
            richTextView.refreshLayoutFor(attachment: attachment)
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

    func displayActions(forAttachment attachment: TextAttachment, position: CGPoint) {
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
                                                self.richTextView.refreshLayoutFor(attachment: attachment)
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

    func displayDetailsForAttachment(_ attachment: TextAttachment, position:CGPoint) {
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
