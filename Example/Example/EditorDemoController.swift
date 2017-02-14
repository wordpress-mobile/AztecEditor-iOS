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

    fileprivate(set) lazy var richTextView: Aztec.TextView = {
        let defaultMissingImage = Gridicon.iconOfType(.image)
        let textView = Aztec.TextView(defaultFont: type(of: self).defaultContentFont, defaultMissingImage: defaultMissingImage)

        let toolbar = self.createToolbar(htmlMode: false)

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, using: toolbar, accessibilityLabel: accessibilityLabel)

        textView.delegate = self
        textView.formattingDelegate = self
        textView.mediaDelegate = self
        textView.addGestureRecognizer(self.tapGestureRecognizer)

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

    fileprivate(set) lazy var tapGestureRecognizer: UIGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(richTextViewWasPressed))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        return recognizer
    }()

    fileprivate var currentSelectedAttachment: TextAttachment?

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
        htmlTextView.inputAccessoryView = createToolbar(htmlMode: true)
        titleTextField.inputAccessoryView = createToolbar(htmlMode: true)
    }
}

extension EditorDemoController : UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        updateFormatBar()
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

        let items = itemsForToolbar

        let toolbar = Aztec.FormatBar()

        if htmlMode {
            for item in items {
                item.isEnabled = false
                if let sourceItem = item as? FormatBarItem, sourceItem.identifier == .sourcecode {
                    item.isEnabled = true
                }
            }
        }

        toolbar.items = items
        toolbar.tintColor = UIColor.gray
        toolbar.highlightedTintColor = UIColor.blue
        toolbar.selectedTintColor = UIColor.darkGray
        toolbar.disabledTintColor = UIColor.lightGray
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.formatter = self

        return toolbar
    }

    var itemsForToolbar: [UIBarButtonItem] {
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let fixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        if self.traitCollection.horizontalSizeClass == .compact {
            let items = [
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.addImage).withRenderingMode(.alwaysTemplate), identifier: .media),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.bold).withRenderingMode(.alwaysTemplate), identifier: .bold),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.italic).withRenderingMode(.alwaysTemplate), identifier: .italic),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.underline).withRenderingMode(.alwaysTemplate), identifier: .underline),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.strikethrough).withRenderingMode(.alwaysTemplate), identifier: .strikethrough),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.quote).withRenderingMode(.alwaysTemplate), identifier: .blockquote),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.listUnordered).withRenderingMode(.alwaysTemplate), identifier: .unorderedlist),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.listOrdered).withRenderingMode(.alwaysTemplate), identifier: .orderedlist),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.link).withRenderingMode(.alwaysTemplate), identifier: .link),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.code).withRenderingMode(.alwaysTemplate), identifier: .sourcecode),
                flex,
                ]
            return items
        } else {
            let items = [
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.addImage).withRenderingMode(.alwaysTemplate), identifier: .media),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.bold).withRenderingMode(.alwaysTemplate), identifier: .bold),
                fixed,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.italic).withRenderingMode(.alwaysTemplate), identifier: .italic),
                fixed,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.underline).withRenderingMode(.alwaysTemplate), identifier: .underline),
                fixed,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.strikethrough).withRenderingMode(.alwaysTemplate), identifier: .strikethrough),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.quote).withRenderingMode(.alwaysTemplate), identifier: .blockquote),
                fixed,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.listUnordered).withRenderingMode(.alwaysTemplate), identifier: .unorderedlist),
                fixed,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.listOrdered).withRenderingMode(.alwaysTemplate), identifier: .orderedlist),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.link).withRenderingMode(.alwaysTemplate), identifier: .link),
                flex,
                Aztec.FormatBarItem(image: Gridicon.iconOfType(.code).withRenderingMode(.alwaysTemplate), identifier: .sourcecode),
                flex,
                ]
            return items
        }
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
    
    func textView(_ textView: TextView, urlForImage image: UIImage) -> URL {
        
        // TODO: start fake upload process
        
        return saveToDisk(image: image)
    }

    func textView(_ textView: TextView, deletedAttachmentWithID attachmentID: String) {
        print("Attachment \(attachmentID) removed.\n")
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
            attachment.progressColor = UIColor.blue            
            if mediaErrorMode && progress.fractionCompleted >= 0.25 {
                timer.invalidate()
                let message = NSAttributedString(string: "Upload failed!", attributes: mediaMessageAttributes)
                attachment.message = message
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
                                                attachment.message = nil
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

// MARK: - UIGestureRecognizerDelegate

extension EditorDemoController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func richTextViewWasPressed(_ recognizer: UIGestureRecognizer) {
        let locationInTextView = recognizer.location(in: richTextView)
        // check if we have an attachment in the position we tapped
        guard let attachment = richTextView.attachmentAtPoint(locationInTextView) else {
            // if we have an attachment marked lets unmark it
            if let selectedAttachment = currentSelectedAttachment {
                selectedAttachment.message = nil
                richTextView.refreshLayoutFor(attachment: selectedAttachment)
                currentSelectedAttachment = nil
            }
            return
        }
        // move the selection to the position of the attachment
        richTextView.moveSelectionToPoint(locationInTextView)
        if attachment == currentSelectedAttachment {
            //if it's the same attachment has before let's display the options
            displayActions(forAttachment: attachment, position: locationInTextView)
        } else {
            // if it's a new attachment tapped let unmark the previous one
            if let selectedAttachment = currentSelectedAttachment {
                selectedAttachment.message = nil
                richTextView.refreshLayoutFor(attachment: selectedAttachment)
            }
            // and mark the newly tapped attachment
            let message = NSLocalizedString("Tap to edit", comment: "Options to show when tapping on a image on the post/page editor.")
            attachment.message = NSAttributedString(string: message, attributes: mediaMessageAttributes)
            richTextView.refreshLayoutFor(attachment: attachment)
            currentSelectedAttachment = attachment
        }
    }
}
