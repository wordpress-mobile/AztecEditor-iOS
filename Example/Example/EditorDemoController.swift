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

    fileprivate(set) lazy var formatBar: Aztec.FormatBar = {
        return self.createToolbar()
    }()

    fileprivate(set) lazy var richTextView: Aztec.TextView = {

        let paragraphStyle = Aztec.ParagraphStyle.default
        
        // This is where you'd normally customize paragraphStyle's values.
        
        let textView = Aztec.TextView(
            defaultFont: Constants.defaultContentFont,
            defaultParagraphStyle: paragraphStyle,
            defaultMissingImage: Constants.defaultMissingImage)

        textView.outputSerializer = DefaultHTMLSerializer(prettyPrint: true)

        textView.inputProcessor =
            PipelineProcessor([CaptionShortcodePreProcessor(),
                               VideoShortcodePreProcessor(),
                               WPVideoShortcodePreProcessor()])

        textView.outputProcessor =
            PipelineProcessor([CaptionShortcodePostProcessor(),
                               VideoShortcodePostProcessor()])

        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self
        textView.accessibilityIdentifier = "richContentView"

        if #available(iOS 11, *) {
            textView.smartDashesType = .no
            textView.smartQuotesType = .no
        }

        return textView
    }()

    fileprivate(set) lazy var htmlTextView: UITextView = {
        let storage = HTMLStorage(defaultFont: Constants.defaultContentFont)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)

        let textView = UITextView(frame: .zero, textContainer: container)

        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)

        textView.isHidden = true
        textView.delegate = self
        textView.accessibilityIdentifier = "HTMLContentView"
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none

        if #available(iOS 11, *) {
            textView.smartDashesType = .no
            textView.smartQuotesType = .no
        }

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

        return textField
    }()

    fileprivate(set) lazy var titlePlaceholderLabel: UILabel = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Label for the title of the post field. Should be the same as WP core.")
        let textField = UILabel()

        textField.attributedText = NSAttributedString(string: placeholderText,
                                                      attributes: [.foregroundColor: UIColor.lightGray,
                                                                   .font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)])
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
                htmlTextView.text = getHTML()
                htmlTextView.becomeFirstResponder()
            case .richText:
                setHTML(htmlTextView.text)
                richTextView.becomeFirstResponder()
            }

            richTextView.isHidden = editingMode == .html
            htmlTextView.isHidden = editingMode == .richText
        }
    }

    fileprivate var currentSelectedAttachment: MediaAttachment?

    let sampleHTML: String?

    func setHTML(_ html: String) {
        richTextView.setHTML(html)
    }

    func getHTML() -> String {
        return richTextView.getHTML()
    }

    fileprivate var optionsViewController: OptionsTableViewController!


    // MARK: - Lifecycle Methods

    init(withSampleHTML sampleHTML: String? = nil) {
        self.sampleHTML = sampleHTML
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        sampleHTML = nil
        
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        MediaAttachment.defaultAppearance.progressColor = UIColor.blue
        MediaAttachment.defaultAppearance.progressBackgroundColor = UIColor.lightGray
        MediaAttachment.defaultAppearance.progressHeight = 2.0
        MediaAttachment.defaultAppearance.overlayColor = UIColor(red: CGFloat(46.0/255.0), green: CGFloat(69.0/255.0), blue: CGFloat(83.0/255.0), alpha: 0.6)
        // Uncomment to add a border
        // MediaAttachment.defaultAppearance.overlayBorderWidth = 3.0
        // MediaAttachment.defaultAppearance.overlayBorderColor = UIColor(red: CGFloat(0.0/255.0), green: CGFloat(135.0/255.0), blue: CGFloat(190.0/255.0), alpha: 0.8)

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

        let html: String

        if let sampleHTML = sampleHTML {
            html = sampleHTML
        } else {
            html = ""
        }

        setHTML(html)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let nc = NotificationCenter.default
        nc.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        nc.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dismissOptionsViewControllerIfNecessary()
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
        let layoutMargins = view.layoutMargins
        let insets = titleTextField.textContainerInset
        let sizeThatShouldFitTheContent = titleTextField.sizeThatFits(CGSize(width:view.frame.width - (insets.left + insets.right + layoutMargins.left + layoutMargins.right), height: CGFloat.greatestFiniteMagnitude))
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
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var safeInsets = self.view.layoutMargins
        safeInsets.top = richTextView.textContainerInset.top
        richTextView.textContainerInset = safeInsets
        htmlTextView.textContainerInset = safeInsets
    }

    private func configureConstraints() {

        titleHeightConstraint = titleTextField.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
        titleTopConstraint = titleTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: -richTextView.contentOffset.y)
        updateTitleHeight()
        let layoutGuide = view.layoutMarginsGuide

        NSLayoutConstraint.activate([
            titleTextField.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            titleTextField.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            titleTopConstraint,
            titleHeightConstraint
            ])

        let insets = titleTextField.textContainerInset
        NSLayoutConstraint.activate([
            titlePlaceholderLabel.leadingAnchor.constraint(equalTo: titleTextField.leadingAnchor, constant: insets.left + titleTextField.textContainer.lineFragmentPadding),
            titlePlaceholderLabel.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor, constant: -insets.right),
            titlePlaceholderLabel.topAnchor.constraint(equalTo: titleTextField.topAnchor, constant: insets.top),
            titlePlaceholderLabel.heightAnchor.constraint(equalToConstant: titleTextField.font!.lineHeight)
            ])
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            separatorView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            separatorView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 0),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activate([
            richTextView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            richTextView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            richTextView.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: 0),
            richTextView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
            ])

        NSLayoutConstraint.activate([
            htmlTextView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            htmlTextView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            htmlTextView.topAnchor.constraint(equalTo: richTextView.topAnchor),
            htmlTextView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            ])
    }


    private func configureDefaultProperties(for textView: UITextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.font = Constants.defaultContentFont
        textView.keyboardDismissMode = .interactive
        textView.textColor = UIColor.darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func registerAttachmentImageProviders() {
        let providers: [TextViewAttachmentImageProvider] = [
            SpecialTagAttachmentRenderer(),
            CommentAttachmentRenderer(font: Constants.defaultContentFont),
            HTMLAttachmentRenderer(font: Constants.defaultHtmlFont)
        ]

        for provider in providers {
            richTextView.registerAttachmentImageProvider(provider)
        }
    }

    // MARK: - Helpers

    @IBAction func toggleEditingMode() {
        formatBar.overflowToolbar(expand: true)
        editingMode.toggle()
    }

    fileprivate func dismissOptionsViewControllerIfNecessary() {
        if let optionsViewController = optionsViewController,
            presentedViewController == optionsViewController {
            dismiss(animated: true, completion: nil)

            self.optionsViewController = nil
        }
    }

    // MARK: - Keyboard Handling

    @objc func keyboardWillShow(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
        dismissOptionsViewControllerIfNecessary()
    }

    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        let referenceView: UIScrollView = editingMode == .richText ? richTextView : htmlTextView

        let scrollInsets = UIEdgeInsets(top: referenceView.scrollIndicatorInsets.top, left: 0, bottom: view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom), right: 0)
        let contentInset = UIEdgeInsets(top: referenceView.contentInset.top, left: 0, bottom: view.frame.maxY - (keyboardFrame.minY + self.view.layoutMargins.bottom), right: 0)

        htmlTextView.scrollIndicatorInsets = scrollInsets
        htmlTextView.contentInset = contentInset

        richTextView.scrollIndicatorInsets = scrollInsets
        richTextView.contentInset = contentInset
    }


    func updateFormatBar() {
        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        let identifiers: [FormattingIdentifier]
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }

        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }

    override var keyCommands: [UIKeyCommand] {
        if richTextView.isFirstResponder {
            return [ UIKeyCommand(input:"B", modifierFlags: .command, action:#selector(toggleBold), discoverabilityTitle:NSLocalizedString("Bold", comment: "Discoverability title for bold formatting keyboard shortcut.")),
                     UIKeyCommand(input:"I", modifierFlags: .command, action:#selector(toggleItalic), discoverabilityTitle:NSLocalizedString("Italic", comment: "Discoverability title for italic formatting keyboard shortcut.")),
                     UIKeyCommand(input:"S", modifierFlags: [.command], action:#selector(toggleStrikethrough), discoverabilityTitle: NSLocalizedString("Strikethrough", comment:"Discoverability title for strikethrough formatting keyboard shortcut.")),
                     UIKeyCommand(input:"U", modifierFlags: .command, action:#selector(EditorDemoController.toggleUnderline(_:)), discoverabilityTitle: NSLocalizedString("Underline", comment:"Discoverability title for underline formatting keyboard shortcut.")),
                     UIKeyCommand(input:"Q", modifierFlags:[.command,.alternate], action: #selector(toggleBlockquote), discoverabilityTitle: NSLocalizedString("Block Quote", comment: "Discoverability title for block quote keyboard shortcut.")),
                     UIKeyCommand(input:"K", modifierFlags:.command, action:#selector(toggleLink), discoverabilityTitle: NSLocalizedString("Insert Link", comment: "Discoverability title for insert link keyboard shortcut.")),
                     UIKeyCommand(input:"M", modifierFlags:[.command,.alternate], action:#selector(showImagePicker), discoverabilityTitle: NSLocalizedString("Insert Media", comment: "Discoverability title for insert media keyboard shortcut.")),
                     UIKeyCommand(input:"U", modifierFlags:[.command, .alternate], action:#selector(toggleUnorderedList), discoverabilityTitle:NSLocalizedString("Bullet List", comment: "Discoverability title for bullet list keyboard shortcut.")),
                     UIKeyCommand(input:"O", modifierFlags:[.command, .alternate], action:#selector(toggleOrderedList), discoverabilityTitle:NSLocalizedString("Numbered List", comment:"Discoverability title for numbered list keyboard shortcut.")),
                     UIKeyCommand(input:"H", modifierFlags:[.command, .shift], action:#selector(toggleEditingMode), discoverabilityTitle:NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."))
            ]
        } else if htmlTextView.isFirstResponder {
            return [UIKeyCommand(input:"H", modifierFlags:[.command, .shift], action:#selector(toggleEditingMode), discoverabilityTitle:NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."))
            ]
        }
        return []
    }


    // MARK: - Sample Content

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if richTextView.resignFirstResponder() {
            richTextView.becomeFirstResponder()
        }

        if htmlTextView.resignFirstResponder() {
            htmlTextView.becomeFirstResponder()
        }

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
        case richTextView:
            updateFormatBar()
        default:
            break
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        switch textView {
        case titleTextField:
            formatBar.enabled = false
        case richTextView:
            formatBar.enabled = true
        case htmlTextView:
            formatBar.enabled = false

            // Disable the bar, except for the source code button
            let htmlButton = formatBar.items.first(where: { $0.identifier == FormattingIdentifier.sourcecode.rawValue })
            htmlButton?.isEnabled = true
        default: break
        }

        textView.inputAccessoryView = formatBar

        return true
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

// MARK: - Format Bar Delegate

extension EditorDemoController : Aztec.FormatBarDelegate {
    func formatBarTouchesBegan(_ formatBar: FormatBar) {
        dismissOptionsViewControllerIfNecessary()
    }

    func formatBar(_ formatBar: FormatBar, didChangeOverflowState state: FormatBarOverflowState) {
        switch state {
        case .hidden:
            print("Format bar collapsed")
        case .visible:
            print("Format bar expanded")
        }
    }
}

// MARK: - Format Bar Actions
extension EditorDemoController {
    func handleAction(for barItem: FormatBarItem) {
        guard let identifier = barItem.identifier,
            let formattingIdentifier = FormattingIdentifier(rawValue: identifier) else {
                return
        }

        switch formattingIdentifier {
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
        case .unorderedlist, .orderedlist:
            toggleList(fromItem: barItem)
        case .link:
            toggleLink()
        case .media:
            break
        case .sourcecode:
            toggleEditingMode()
        case .p, .header1, .header2, .header3, .header4, .header5, .header6:
            toggleHeader(fromItem: barItem)
        case .more:
            insertMoreAttachment()
        case .horizontalruler:
            insertHorizontalRuler()
        }

        updateFormatBar()
    }

    @objc func toggleBold() {
        richTextView.toggleBold(range: richTextView.selectedRange)
    }


    @objc func toggleItalic() {
        richTextView.toggleItalic(range: richTextView.selectedRange)
    }


    func toggleUnderline() {
        richTextView.toggleUnderline(range: richTextView.selectedRange)
    }


    @objc func toggleStrikethrough() {
        richTextView.toggleStrikethrough(range: richTextView.selectedRange)
    }

    @objc func toggleBlockquote() {
        richTextView.toggleBlockquote(range: richTextView.selectedRange)
    }

    func insertHorizontalRuler() {
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
    }

    func toggleHeader(fromItem item: FormatBarItem) {
        let headerOptions = Constants.headers.map { headerType -> OptionsTableViewOption in
            let attributes: [NSAttributedStringKey: Any] = [
                .font: UIFont.systemFont(ofSize: CGFloat(headerType.fontSize))
            ]

            let title = NSAttributedString(string: headerType.description, attributes: attributes)
            return OptionsTableViewOption(image: headerType.iconImage, title: title)
        }

        let selectedIndex = Constants.headers.index(of: self.headerLevelForSelectedText())

        showOptionsTableViewControllerWithOptions(headerOptions,
                                                  fromBarItem: item,
                                                  selectedRowIndex: selectedIndex,
                                                  onSelect: { [weak self] selected in
            guard let range = self?.richTextView.selectedRange else {
                return
            }

            self?.richTextView.toggleHeader(Constants.headers[selected], range: range)
            self?.optionsViewController = nil
            self?.changeRichTextInputView(to: nil)
        })
    }

    func toggleList(fromItem item: FormatBarItem) {
        let listOptions = Constants.lists.map { (listType) -> OptionsTableViewOption in
            return OptionsTableViewOption(image: listType.iconImage, title: NSAttributedString(string: listType.description, attributes: [:]))
        }

        var index: Int? = nil
        if let listType = listTypeForSelectedText() {
            index = Constants.lists.index(of: listType)
        }

        showOptionsTableViewControllerWithOptions(listOptions,
                                                  fromBarItem: item,
                                                  selectedRowIndex: index,
                                                  onSelect: { [weak self] selected in
            guard let range = self?.richTextView.selectedRange else { return }

            let listType = Constants.lists[selected]
            switch listType {
            case .unordered:
                self?.richTextView.toggleUnorderedList(range: range)
            case .ordered:
                self?.richTextView.toggleOrderedList(range: range)
            }

            self?.optionsViewController = nil
        })
    }

    @objc func toggleUnorderedList() {
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }

    @objc func toggleOrderedList() {
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }

    func showOptionsTableViewControllerWithOptions(_ options: [OptionsTableViewOption],
                                                   fromBarItem barItem: FormatBarItem,
                                                   selectedRowIndex index: Int?,
                                                   onSelect: OptionsTableViewController.OnSelectHandler?) {
        // Hide the input view if we're already showing these options
        if let optionsViewController = optionsViewController,
            optionsViewController.options == options {
            if presentedViewController != nil {
              dismiss(animated: true, completion: nil)
            }

            self.optionsViewController = nil
            changeRichTextInputView(to: nil)
            return
        }

        optionsViewController = OptionsTableViewController(options: options)
        optionsViewController.cellDeselectedTintColor = .gray
        optionsViewController.onSelect = { [weak self] selected in
            if self?.presentedViewController != nil {
                self?.dismiss(animated: true, completion: nil)
            }

            onSelect?(selected)
        }

        let selectRow = {
            if let index = index {
                self.optionsViewController.selectRow(at: index)
            }
        }

        if UIDevice.current.userInterfaceIdiom == .pad  {
            presentOptionsViewController(optionsViewController, asPopoverFromBarItem: barItem, completion: selectRow)
        } else {
            presentOptionsViewControllerAsInputView(optionsViewController)
            selectRow()
        }
    }

    private func presentOptionsViewController(_ optionsViewController: OptionsTableViewController,
                                              asPopoverFromBarItem barItem: FormatBarItem,
                                              completion: (() -> Void)? = nil) {
        optionsViewController.modalPresentationStyle = .popover
        optionsViewController.popoverPresentationController?.permittedArrowDirections = [.down]
        optionsViewController.popoverPresentationController?.sourceView = view

        let frame = barItem.superview?.convert(barItem.frame, to: UIScreen.main.coordinateSpace)

        optionsViewController.popoverPresentationController?.sourceRect = view.convert(frame!, from: UIScreen.main.coordinateSpace)
        optionsViewController.popoverPresentationController?.backgroundColor = .white
        optionsViewController.popoverPresentationController?.delegate = self

        if presentedViewController != nil {
            dismiss(animated: true, completion: {
                self.present(self.optionsViewController, animated: true, completion: completion)
            })
        } else {
            present(optionsViewController, animated: true, completion: completion)
        }
    }

    private func presentOptionsViewControllerAsInputView(_ optionsViewController: OptionsTableViewController) {
        self.addChildViewController(optionsViewController)
        changeRichTextInputView(to: optionsViewController.view)
        optionsViewController.didMove(toParentViewController: self)
    }

    func changeRichTextInputView(to: UIView?) {
        if richTextView.inputView == to {
            return
        }

        richTextView.inputView = to
        richTextView.reloadInputViews()
    }

    func headerLevelForSelectedText() -> Header.HeaderType {
        var identifiers = [FormattingIdentifier]()
        if (richTextView.selectedRange.length > 0) {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: Header.HeaderType] = [
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

    func listTypeForSelectedText() -> TextList.Style? {
        var identifiers = [FormattingIdentifier]()
        if (richTextView.selectedRange.length > 0) {
            identifiers = richTextView.formatIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formatIdentifiersForTypingAttributes()
        }
        let mapping: [FormattingIdentifier: TextList.Style] = [
            .orderedlist : .ordered,
            .unorderedlist : .unordered
            ]
        for (key,value) in mapping {
            if identifiers.contains(key) {
                return value
            }
        }

        return nil
    }

    @objc func toggleLink() {
        var linkTitle = ""
        var linkURL: URL? = nil
        var linkRange = richTextView.selectedRange
        // Let's check if the current range already has a link assigned to it.
        if let expandedRange = richTextView.linkFullRange(forRange: richTextView.selectedRange) {
           linkRange = expandedRange
           linkURL = richTextView.linkURL(forRange: expandedRange)
        }

        linkTitle = richTextView.attributedText.attributedSubstring(from: linkRange).string
        let allowTextEdit = !richTextView.attributedText.containsAttachments(in: linkRange)
        showLinkDialog(forURL: linkURL, text: linkTitle, range: linkRange, allowTextEdit: allowTextEdit)
    }

    func insertMoreAttachment() {
        richTextView.replace(richTextView.selectedRange, withComment: Constants.moreAttachmentText)
    }

    func showLinkDialog(forURL url: URL?, text: String?, range: NSRange, allowTextEdit: Bool = true) {

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

        if allowTextEdit {
            alertController.addTextField(configurationHandler: { textField in
                textField.clearButtonMode = UITextFieldViewMode.always
                textField.placeholder = NSLocalizedString("Link Text", comment:"Link text field placeholder")
                textField.isSecureTextEntry = false
                textField.autocapitalizationType = UITextAutocapitalizationType.sentences
                textField.autocorrectionType = UITextAutocorrectionType.default
                textField.spellCheckingType = UITextSpellCheckingType.default

                textField.text = text;

                })
        }
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
                                                let url = URL(string:urlString)
                                                else {
                                                    return
                                            }
                                            if allowTextEdit {
                                                if let title = linkTitle {
                                                    self?.richTextView.setLink(url, title:title, inRange: range)
                                                }
                                            } else {
                                                self?.richTextView.setLink(url, inRange: range)
                                            }
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

    @objc func alertTextFieldDidChange(_ textField: UITextField) {
        guard
            let alertController = presentedViewController as? UIAlertController,
            let urlFieldText = alertController.textFields?.first?.text,
            let insertAction = alertController.actions.first
            else {
            return
        }

        insertAction.isEnabled = !urlFieldText.isEmpty
    }


    @objc func showImagePicker() {
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
        let button = FormatBarItem(image: identifier.iconImage, identifier: identifier.rawValue)
        button.accessibilityLabel = identifier.accessibilityLabel
        button.accessibilityIdentifier = identifier.accessibilityIdentifier
        return button
    }

    func createToolbar() -> Aztec.FormatBar {
        let mediaItem = makeToolbarButton(identifier: .media)
        let scrollableItems = scrollableItemsForToolbar
        let overflowItems = overflowItemsForToolbar

        let toolbar = Aztec.FormatBar()

        toolbar.tintColor = .gray
        toolbar.highlightedTintColor = .blue
        toolbar.selectedTintColor = view.tintColor
        toolbar.disabledTintColor = .lightGray
        toolbar.dividerTintColor = .gray

        toolbar.overflowToggleIcon = Gridicon.iconOfType(.ellipsis)
        toolbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0)
        toolbar.autoresizingMask = [ .flexibleHeight ]
        toolbar.formatter = self

        toolbar.leadingItem = mediaItem
        toolbar.setDefaultItems(scrollableItems,
                                overflowItems: overflowItems)

        toolbar.barItemHandler = { [weak self] item in
            self?.handleAction(for: item)
        }

        toolbar.leadingItemHandler = { [weak self] item in
            self?.showImagePicker()
        }

        return toolbar
    }

    var scrollableItemsForToolbar: [FormatBarItem] {
        let headerButton = makeToolbarButton(identifier: .p)

        var alternativeIcons = [String: UIImage]()
        let headings = Constants.headers.suffix(from: 1) // Remove paragraph style
        for heading in headings {
            alternativeIcons[heading.formattingIdentifier.rawValue] = heading.iconImage
        }

        headerButton.alternativeIcons = alternativeIcons


        let listButton = makeToolbarButton(identifier: .unorderedlist)
        var listIcons = [String: UIImage]()
        for list in Constants.lists {
            listIcons[list.formattingIdentifier.rawValue] = list.iconImage
        }

        listButton.alternativeIcons = listIcons

        return [
            headerButton,
            listButton,
            makeToolbarButton(identifier: .blockquote),
            makeToolbarButton(identifier: .bold),
            makeToolbarButton(identifier: .italic),
            makeToolbarButton(identifier: .link)
        ]
    }

    var overflowItemsForToolbar: [FormatBarItem] {
        return [
            makeToolbarButton(identifier: .underline),
            makeToolbarButton(identifier: .strikethrough),
            makeToolbarButton(identifier: .horizontalruler),
            makeToolbarButton(identifier: .more),
            makeToolbarButton(identifier: .sourcecode)
        ]
    }

}


extension EditorDemoController: TextViewAttachmentDelegate {

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {

        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            DispatchQueue.main.async {
                guard self != nil else {
                    return
                }

                guard error == nil, let data = data, let image = UIImage(data: data, scale: UIScreen.main.scale) else {
                    failure()
                    return
                }

                success(image)
            }
        }

        task.resume()
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return placeholderImage(for: attachment)
    }

    func placeholderImage(for attachment: NSTextAttachment) -> UIImage {
        let imageSize = CGSize(width:32, height:32)
        let placeholderImage: UIImage
        switch attachment {
        case _ as ImageAttachment:
            placeholderImage = Gridicon.iconOfType(.image, withSize: imageSize)
        case _ as VideoAttachment:
            placeholderImage = Gridicon.iconOfType(.video, withSize: imageSize)
        default:
            placeholderImage = Gridicon.iconOfType(.attachment, withSize: imageSize)
        }

        return placeholderImage
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        guard let image = imageAttachment.image else {
            return nil
        }

        // TODO: start fake upload process
        return saveToDisk(image: image)
    }

    func textView(_ textView: TextView, deletedAttachmentWith attachmentID: String) {
        print("Attachment \(attachmentID) removed.\n")
    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        switch attachment {
        case let attachment as HTMLAttachment:
            displayUnknownHtmlEditor(for: attachment)
        case let attachment as MediaAttachment:
            selected(textAttachment: attachment, atPosition: position)
        default:
            break
        }
    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        deselected(textAttachment: attachment, atPosition: position)
    }

    fileprivate func resetMediaAttachmentOverlay(_ mediaAttachment: MediaAttachment) {
        mediaAttachment.overlayImage = nil
        mediaAttachment.message = nil
    }

    func selected(textAttachment attachment: MediaAttachment, atPosition position: CGPoint) {
        if (currentSelectedAttachment == attachment) {
            displayActions(forAttachment: attachment, position: position)
        } else {
            if let selectedAttachment = currentSelectedAttachment {
                resetMediaAttachmentOverlay(selectedAttachment)
                richTextView.refresh(selectedAttachment)
            }

            // and mark the newly tapped attachment
            if attachment.message == nil {
                let message = NSLocalizedString("Options", comment: "Options to show when tapping on a media object on the post/page editor.")
                attachment.message = NSAttributedString(string: message, attributes: mediaMessageAttributes)
            }
            attachment.overlayImage = Gridicon.iconOfType(.pencil, withSize: CGSize(width: 32.0, height: 32.0)).withRenderingMode(.alwaysTemplate)
            richTextView.refresh(attachment)
            currentSelectedAttachment = attachment
        }
    }

    func deselected(textAttachment attachment: NSTextAttachment, atPosition position: CGPoint) {
        currentSelectedAttachment = nil
        if let mediaAttachment = attachment as? MediaAttachment {
            resetMediaAttachmentOverlay(mediaAttachment)
            richTextView.refresh(mediaAttachment)
        }
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
            self?.richTextView.edit(attachment) { updated in
                updated.rawHTML = html
            }

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

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        if optionsViewController != nil {
            optionsViewController = nil
        }
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
        
        let fileURL = saveToDisk(image: image)
        
        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange, sourceURL: fileURL, placeHolderImage: image)
        attachment.size = .full
        attachment.linkURL = fileURL
        let imageID = attachment.identifier
        let progress = Progress(parent: nil, userInfo: [MediaProgressKey.mediaID: imageID])
        progress.totalUnitCount = 100
        
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(EditorDemoController.timerFireMethod(_:)), userInfo: progress, repeats: true)
    }

    func insertVideo(_ videoURL: URL) {
        let asset = AVURLAsset(url: videoURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        guard let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil) else {
            return
        }
        let posterImage = UIImage(cgImage: cgImage)
        let posterURL = saveToDisk(image: posterImage)
        let attachment = richTextView.replaceWithVideo(at: richTextView.selectedRange, sourceURL: URL(string:"placeholder://")!, posterURL: posterURL, placeHolderImage: posterImage)
        let mediaID = attachment.identifier
        let progress = Progress(parent: nil, userInfo: [MediaProgressKey.mediaID: mediaID, MediaProgressKey.videoURL:videoURL])
        progress.totalUnitCount = 100

        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(EditorDemoController.timerFireMethod(_:)), userInfo: progress, repeats: true)
    }

    @objc func timerFireMethod(_ timer: Timer) {
        guard let progress = timer.userInfo as? Progress,
              let imageId = progress.userInfo[MediaProgressKey.mediaID] as? String,
              let attachment = richTextView.attachment(withId: imageId)
        else {
            timer.invalidate()
            return
        }        
        progress.completedUnitCount += 1

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
            if let videoAttachment = attachment as? VideoAttachment, let videoURL = progress.userInfo[MediaProgressKey.videoURL] as? URL {
                videoAttachment.srcURL = videoURL
            }
        }
        richTextView.refresh(attachment)
    }

    var mediaMessageAttributes: [NSAttributedStringKey: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                                                        .paragraphStyle: paragraphStyle,
                                                        .foregroundColor: UIColor.white]
        return attributes
    }

    func displayActions(forAttachment attachment: MediaAttachment, position: CGPoint) {
        let mediaID = attachment.identifier
        let title: String = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        let message: String? = nil
        let alertController = UIAlertController(title: title, message:message, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "User action to dismiss media options."),
                                          style: .cancel,
                                          handler: { (action) in
                                            self.resetMediaAttachmentOverlay(attachment)
                                            self.richTextView.refresh(attachment)
        }
        )
        alertController.addAction(dismissAction)

        let removeAction = UIAlertAction(title: NSLocalizedString("Remove Media", comment: "User action to remove media."),
                                         style: .destructive,
                                         handler: { (action) in
                                            self.richTextView.remove(attachmentID: mediaID)
        })
        alertController.addAction(removeAction)

        if let imageAttachment = attachment as? ImageAttachment {
            let detailsAction = UIAlertAction(title:NSLocalizedString("Media Details", comment: "User action to change media details."),
                                              style: .default,
                                              handler: { (action) in
                                                self.displayDetailsForAttachment(imageAttachment, position: position)
            })
            alertController.addAction(detailsAction)
        } else if let videoAttachment = attachment as? VideoAttachment, let videoURL = videoAttachment.srcURL {
            let detailsAction = UIAlertAction(title:NSLocalizedString("Play Video", comment: "User action to play video."),
                                              style: .default,
                                              handler: { (action) in
                                                self.displayVideoPlayer(for: videoURL)
            })
            alertController.addAction(detailsAction)
        }

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
        detailsViewController.onUpdate = { (alignment, size, url, linkURL, alt) in
            self.richTextView.edit(attachment) { updated in
                if let alt = alt {
                    updated.extraAttributes["alt"] = alt
                }

                updated.alignment = alignment
                updated.size = size
                updated.linkURL = linkURL

                updated.updateURL(url)
            }
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
        static let formatBarIconSize    = CGSize(width: 20.0, height: 20.0)
        static let headers              = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists                = [TextList.Style.unordered, .ordered]        
        static let moreAttachmentText   = "more"
    }

    struct MediaProgressKey {
        static let mediaID = ProgressUserInfoKey("mediaID")
        static let videoURL = ProgressUserInfoKey("videoURL")
    }
}

extension FormattingIdentifier {

    var iconImage: UIImage {

        switch(self) {
        case .media:
            return gridicon(.addOutline)
        case .p:
            return gridicon(.heading)
        case .bold:
            return gridicon(.bold)
        case .italic:
            return gridicon(.italic)
        case .underline:
            return gridicon(.underline)
        case .strikethrough:
            return gridicon(.strikethrough)
        case .blockquote:
            return gridicon(.quote)
        case .orderedlist:
            return gridicon(.listOrdered)
        case .unorderedlist:
            return gridicon(.listUnordered)
        case .link:
            return gridicon(.link)
        case .horizontalruler:
            return gridicon(.minusSmall)
        case .sourcecode:
            return gridicon(.code)
        case .more:
            return gridicon(.readMore)
        case .header1:
            return gridicon(.headingH1)
        case .header2:
            return gridicon(.headingH2)
        case .header3:
            return gridicon(.headingH3)
        case .header4:
            return gridicon(.headingH4)
        case .header5:
            return gridicon(.headingH5)
        case .header6:
            return gridicon(.headingH6)
        }
    }

    private func gridicon(_ gridiconType: GridiconType) -> UIImage {
        let size = EditorDemoController.Constants.formatBarIconSize
        return Gridicon.iconOfType(gridiconType, withSize: size)
    }

    var accessibilityIdentifier: String {
        switch(self) {
        case .media:
            return "formatToolbarInsertMedia"
        case .p:
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
        }
    }

    var accessibilityLabel: String {
        switch(self) {
        case .media:
            return NSLocalizedString("Insert media", comment: "Accessibility label for insert media button on formatting toolbar.")
        case .p:
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
            return NSLocalizedString("Heading 1", comment: "Accessibility label for selecting h1 paragraph style button on the formatting toolbar.")
        case .header2:
            return NSLocalizedString("Heading 2", comment: "Accessibility label for selecting h2 paragraph style button on the formatting toolbar.")
        case .header3:
            return NSLocalizedString("Heading 3", comment: "Accessibility label for selecting h3 paragraph style button on the formatting toolbar.")
        case .header4:
            return NSLocalizedString("Heading 4", comment: "Accessibility label for selecting h4 paragraph style button on the formatting toolbar.")
        case .header5:
            return NSLocalizedString("Heading 5", comment: "Accessibility label for selecting h5 paragraph style button on the formatting toolbar.")
        case .header6:
            return NSLocalizedString("Heading 6", comment: "Accessibility label for selecting h6 paragraph style button on the formatting toolbar.")
        }
    }
}

// MARK: - Header and List presentation extensions

private extension Header.HeaderType {
    var formattingIdentifier: FormattingIdentifier {
        switch self {
        case .none: return FormattingIdentifier.p
        case .h1:   return FormattingIdentifier.header1
        case .h2:   return FormattingIdentifier.header2
        case .h3:   return FormattingIdentifier.header3
        case .h4:   return FormattingIdentifier.header4
        case .h5:   return FormattingIdentifier.header5
        case .h6:   return FormattingIdentifier.header6
        }
    }

    var description: String {
        switch self {
        case .none: return NSLocalizedString("Default", comment: "Description of the default paragraph formatting style in the editor.")
        case .h1: return "Heading 1"
        case .h2: return "Heading 2"
        case .h3: return "Heading 3"
        case .h4: return "Heading 4"
        case .h5: return "Heading 5"
        case .h6: return "Heading 6"
        }
    }

    var iconImage: UIImage? {
        return formattingIdentifier.iconImage
    }
}

private extension TextList.Style {
    var formattingIdentifier: FormattingIdentifier {
        switch self {
        case .ordered:   return FormattingIdentifier.orderedlist
        case .unordered: return FormattingIdentifier.unorderedlist
        }
    }

    var description: String {
        switch self {
        case .ordered: return "Ordered List"
        case .unordered: return "Unordered List"
        }
    }

    var iconImage: UIImage? {
        return formattingIdentifier.iconImage
    }
}
