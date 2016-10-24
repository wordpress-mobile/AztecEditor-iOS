import Foundation
import Aztec
import Gridicons
import Photos
import UIKit


class EditorDemoController: UIViewController {
    static let margin = CGFloat(20)
    static let defaultContentFont = UIFont.systemFontOfSize(14)

    private(set) lazy var richTextView: Aztec.TextView = {
        let defaultMissingImage = Gridicon.iconOfType(.Image)
        let textView = Aztec.TextView(defaultFont: self.dynamicType.defaultContentFont, defaultMissingImage: defaultMissingImage)

        textView.accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        textView.delegate = self
        textView.mediaDelegate = self
        textView.font = defaultContentFont

        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.formatter = self

        textView.inputAccessoryView = toolbar
        textView.textColor = UIColor.darkTextColor()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.addGestureRecognizer(self.tapGestureRecognizer)

        return textView
    }()

    private(set) lazy var htmlTextView: UITextView = {
        let textView = UITextView()

        textView.accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        textView.font = defaultContentFont
        textView.textColor = UIColor.darkTextColor()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.hidden = true

        return textView
    }()

    private(set) lazy var titleTextField: UITextField = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Label for the title of the post field. Should be the same as WP core.")
        let textField = UITextField()

        textField.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText,
                                                      attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        textField.delegate = self
        textField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let toolbar = self.createToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0)
        toolbar.enabled = false
        textField.inputAccessoryView = toolbar
        textField.returnKeyType = .Next
        textField.textColor = UIColor.darkTextColor()
        textField.translatesAutoresizingMaskIntoConstraints = false

        return textField
    }()

    private(set) lazy var separatorView: UIView = {
        let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        separatorView.backgroundColor = UIColor.darkTextColor()
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        return separatorView
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

    private(set) lazy var tapGestureRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(richTextViewWasPressed))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        return recognizer
    }()

    var loadSampleHTML = false


    // MARK: - Lifecycle Methods

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .None
        navigationController?.navigationBar.translucent = false

        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(titleTextField)
        view.addSubview(separatorView)
        view.addSubview(richTextView)
        view.addSubview(htmlTextView)

        configureConstraints()
        configureNavigationBar()

        let html: String

        if loadSampleHTML {
            html = getSampleHTML()
        } else {
            html = ""
        }

        richTextView.setHTML(html)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

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

        let range = richTextView.selectedRange
        let identifiers = richTextView.formatIdentifiersSpanningRange(range)
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
        
        htmlTextView.text = richTextView.getHTML()
        view.endEditing(true)
        htmlTextView.hidden = false
        richTextView.hidden = true
    }

    private func switchToRichText() {
        navigationItem.rightBarButtonItem?.title = NSLocalizedString("HTML", comment: "HTML!")

        richTextView.setHTML(htmlTextView.text)

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
        var linkURL: NSURL? = nil
        var linkRange = richTextView.selectedRange
        // Let's check if the current range already has a link assigned to it.
        if let expandedRange = richTextView.linkFullRange(forRange: richTextView.selectedRange) {
           linkRange = expandedRange
           linkURL = richTextView.linkURL(forRange: expandedRange)
        }

        linkTitle = richTextView.attributedText.attributedSubstringFromRange(linkRange).string
        showLinkDialog(forURL: linkURL, title: linkTitle, range: linkRange)
    }

    func showLinkDialog(forURL url: NSURL?, title: String?, range: NSRange) {

        let isInsertingNewLink = (url == nil)
        // TODO: grab link from pasteboard if available

        let insertButtonTitle = isInsertingNewLink ? NSLocalizedString("Insert Link", comment:"Label action for inserting a link on the editor") : NSLocalizedString("Update Link", comment:"Label action for updating a link on the editor")
        let removeButtonTitle = NSLocalizedString("Remove Link", comment:"Label action for removing a link from the editor");
        let cancelButtonTitle = NSLocalizedString("Cancel", comment:"Cancel button")

        let alertController = UIAlertController(title:insertButtonTitle,
                                                message:nil,
                                                preferredStyle:UIAlertControllerStyle.Alert)

        alertController.addTextFieldWithConfigurationHandler({ [weak self]textField in
            textField.clearButtonMode = UITextFieldViewMode.Always;
            textField.placeholder = NSLocalizedString("URL", comment:"URL text field placeholder");

            textField.text = url?.absoluteString

            textField.addTarget(self,
                action:#selector(EditorDemoController.alertTextFieldDidChange),
            forControlEvents:UIControlEvents.EditingChanged)
            })

        alertController.addTextFieldWithConfigurationHandler({ textField in
            textField.clearButtonMode = UITextFieldViewMode.Always
            textField.placeholder = NSLocalizedString("Link Name", comment:"Link name field placeholder")
            textField.secureTextEntry = false
            textField.autocapitalizationType = UITextAutocapitalizationType.Sentences
            textField.autocorrectionType = UITextAutocorrectionType.Default
            textField.spellCheckingType = UITextSpellCheckingType.Default

            textField.text = title;

            })

        let insertAction = UIAlertAction(title:insertButtonTitle,
                                         style:UIAlertActionStyle.Default,
                                         handler:{ [weak self]action in

                                            self?.richTextView.becomeFirstResponder()
                                            let linkURLString = alertController.textFields?.first?.text
                                            var linkTitle = alertController.textFields?.last?.text

                                            if  linkTitle == nil  || linkTitle!.isEmpty {
                                                linkTitle = linkURLString
                                            }

                                            guard
                                                let urlString = linkURLString,
                                                let url = NSURL(string:urlString),
                                                let title = linkTitle
                                                else {
                                                    return
                                            }
                                            self?.richTextView.setLink(url, title:title, inRange: range)
                                            })

        let removeAction = UIAlertAction(title:removeButtonTitle,
                                         style:UIAlertActionStyle.Destructive,
                                         handler:{ [weak self] action in
                                            self?.richTextView.becomeFirstResponder()
                                            self?.richTextView.removeLink(inRange: range)
            })

        let cancelAction = UIAlertAction(title: cancelButtonTitle,
                                         style:UIAlertActionStyle.Cancel,
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
            insertAction.enabled = !text.isEmpty
        }

        self.presentViewController(alertController, animated:true, completion:nil)
    }

    func alertTextFieldDidChange(textField: UITextField) {
        guard
            let alertController = presentedViewController as? UIAlertController,
            let urlFieldText = alertController.textFields?.first?.text,
            let insertAction = alertController.actions.first
            else {
            return
        }

        insertAction.enabled = !urlFieldText.isEmpty
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

extension EditorDemoController: TextViewMediaDelegate
{
    func textView(textView: TextView, imageAtUrl url: NSURL, onSuccess success: UIImage -> Void, onFailure failure: Void -> Void) -> UIImage {

        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, urlResponse, error) in
            dispatch_async(
                dispatch_get_main_queue(), {
                    guard
                        error == nil,
                        let data = data,
                        let image = UIImage(data: data, scale:UIScreen.mainScreen().scale)
                    else {
                        failure()
                        return
                    }
                    success(image)
            })
        }
        task.resume()

        return Gridicon.iconOfType(.Image)
    }
    
    func textView(textView: TextView, urlForImage image: UIImage) -> NSURL {
        
        // TODO: start fake upload process
        
        return saveToDisk(image: image)
    }
}


extension EditorDemoController: UINavigationControllerDelegate
{

}


extension EditorDemoController: UIImagePickerControllerDelegate
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
    private func saveToDisk(image image: UIImage) -> NSURL {
        let fileName = "\(NSProcessInfo.processInfo().globallyUniqueString)_file.jpg"
        guard
            let data = UIImageJPEGRepresentation(image, 0.9),
            let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(fileName)
            where data.writeToURL(fileURL, atomically:true)
            else {
                fatalError("Could not save image to disk.")
        }
        
        return fileURL
    }
    
    func insertImage(image: UIImage) {
        
        let index = richTextView.positionForCursor()
        let fileURL = saveToDisk(image: image)
        
        richTextView.insertImage(sourceURL: fileURL, atPosition: index, placeHolderImage: image)
    }

    func displayDetailsForAttachment(attachment: TextAttachment, position:CGPoint) {
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
        presentViewController(navigationController, animated: true, completion: nil)
    }
}


extension EditorDemoController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func richTextViewWasPressed(recognizer: UIGestureRecognizer) {
        let locationInTextView = recognizer.locationInView(richTextView)
        guard let attachment = richTextView.attachmentAtPoint(locationInTextView) else {
            return
        }

        displayDetailsForAttachment(attachment, position:locationInTextView)
    }
}
