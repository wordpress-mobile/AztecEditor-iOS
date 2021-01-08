import Aztec
import Foundation
import MobileCoreServices
import Photos
import UIKit
import WordPressEditor

class EditorDemoController: UIViewController {    

    fileprivate(set) lazy var formatBar: Aztec.FormatBar = {
        return self.createToolbar()
    }()
    
    private var richTextView: TextView {
        get {
            return editorView.richTextView
        }
    }
    
    private var htmlTextView: UITextView {
        get {
            return editorView.htmlTextView
        }
    }

    fileprivate(set) lazy var mediaInserter: MediaInserter = {
        return MediaInserter(textView: self.richTextView, attachmentTextAttributes: Constants.mediaMessageAttributes)
    }()

    fileprivate(set) lazy var textViewAttachmentDelegate: TextViewAttachmentDelegate = {
        return TextViewAttachmentDelegateProvider(baseController: self, attachmentTextAttributes: Constants.mediaMessageAttributes)
    }()
    
    fileprivate(set) lazy var editorView: Aztec.EditorView = {
        let defaultHTMLFont: UIFont

        defaultHTMLFont = UIFontMetrics.default.scaledFont(for: Constants.defaultContentFont)
        
        let editorView = Aztec.EditorView(
            defaultFont: Constants.defaultContentFont,
            defaultHTMLFont: defaultHTMLFont,
            defaultParagraphStyle: .default,
            defaultMissingImage: Constants.defaultMissingImage)

        editorView.clipsToBounds = false
        setupHTMLTextView(editorView.htmlTextView)
        setupRichTextView(editorView.richTextView)
        
        return editorView
    }()
    
    private func setupRichTextView(_ textView: TextView) {
        if wordPressMode {
            textView.load(WordPressPlugin())
        }
        
        let accessibilityLabel = NSLocalizedString("Rich Content", comment: "Post Rich content")
        self.configureDefaultProperties(for: textView, accessibilityLabel: accessibilityLabel)
        
        textView.delegate = self
        textView.formattingDelegate = self
        textView.textAttachmentDelegate = self.textViewAttachmentDelegate
        textView.accessibilityIdentifier = "richContentView"
        textView.clipsToBounds = false
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }
    
    private func setupHTMLTextView(_ textView: UITextView) {
        let accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        self.configureDefaultProperties(htmlTextView: textView, accessibilityLabel: accessibilityLabel)
        
        textView.isHidden = true
        textView.delegate = self
        textView.accessibilityIdentifier = "HTMLContentView"
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.clipsToBounds = false
        textView.adjustsFontForContentSizeCategory = true

        textView.smartDashesType = .no
        textView.smartQuotesType = .no
    }

    fileprivate(set) lazy var titleTextView: UITextView = {
        let textView = UITextView()
        
        textView.accessibilityLabel = NSLocalizedString("Title", comment: "Post title")
        textView.delegate = self
        textView.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        textView.returnKeyType = .next
        textView.textColor = .darkText
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textAlignment = .natural
        textView.isScrollEnabled = false

        return textView
    }()

    /// Placeholder Label
    ///
    fileprivate(set) lazy var titlePlaceholderLabel: UILabel = {
        let placeholderText = NSLocalizedString("Enter title here", comment: "Post title placeholder")
        let titlePlaceholderLabel = UILabel()

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.lightGray, .font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)]

        titlePlaceholderLabel.attributedText = NSAttributedString(string: placeholderText, attributes: attributes)
        titlePlaceholderLabel.sizeToFit()
        titlePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        titlePlaceholderLabel.textAlignment = .natural

        return titlePlaceholderLabel
    }()

    fileprivate var titleHeightConstraint: NSLayoutConstraint!
    fileprivate var titleTopConstraint: NSLayoutConstraint!
    fileprivate var titlePlaceholderTopConstraint: NSLayoutConstraint!
    fileprivate var titlePlaceholderLeadingConstraint: NSLayoutConstraint!

    fileprivate(set) lazy var separatorView: UIView = {
        let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 1))

        separatorView.backgroundColor = UIColor.darkText
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        return separatorView
    }()    

    let sampleHTML: String?
    let wordPressMode: Bool

    private lazy var optionsTablePresenter = OptionsTablePresenter(presentingViewController: self, presentingTextView: richTextView)

    // MARK: - Lifecycle Methods

    init(withSampleHTML sampleHTML: String? = nil, wordPressMode: Bool) {
        
        self.sampleHTML = sampleHTML
        self.wordPressMode = wordPressMode
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        sampleHTML = nil
        wordPressMode = false
        
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
        view.addSubview(editorView)
        view.addSubview(titleTextView)
        view.addSubview(titlePlaceholderLabel)
        view.addSubview(separatorView)

        editorView.richTextView.textContainer.lineFragmentPadding = 0
        // color setup
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
            titleTextView.textColor = UIColor.label
            editorView.htmlTextView.textColor = UIColor.label
            editorView.richTextView.textColor = UIColor.label
            editorView.richTextView.blockquoteBackgroundColor = UIColor.secondarySystemBackground
            editorView.richTextView.preBackgroundColor = UIColor.secondarySystemBackground
            editorView.richTextView.blockquoteBorderColors = [.secondarySystemFill, .systemTeal, .systemBlue]
            var attributes = editorView.richTextView.linkTextAttributes
            attributes?[.foregroundColor] =  UIColor.link
        } else {
            view.backgroundColor = UIColor.white
        }
        //Don't allow scroll while the constraints are being setup and text set
        editorView.isScrollEnabled = false
        configureConstraints()
        registerAttachmentImageProviders()

        let html: String

        if let sampleHTML = sampleHTML {
            html = sampleHTML
        } else {
            html = ""
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(changeFont))
        editorView.setHTML(html)
        editorView.becomeFirstResponder()
    }

    @objc func changeFont() {
        editorView.richTextView.defaultFont = UIFont.preferredFont(forTextStyle: .callout)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Reanable scroll after setup is done
        editorView.isScrollEnabled = true
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        optionsTablePresenter.dismiss()
    }

    // MARK: - Title and Title placeholder position methods
    func updateTitlePosition() {
        titleTopConstraint.constant = -(editorView.contentOffset.y + editorView.contentInset.top)
        titlePlaceholderTopConstraint.constant = titleTextView.textContainerInset.top + titleTextView.contentInset.top
        titlePlaceholderLeadingConstraint.constant = titleTextView.textContainerInset.left + titleTextView.contentInset.left  + titleTextView.textContainer.lineFragmentPadding
        
        var contentInset = editorView.contentInset
        contentInset.top = titleHeightConstraint.constant + separatorView.frame.height
        editorView.contentInset = contentInset
        
        updateScrollInsets()
    }

    func updateScrollInsets() {
        var scrollInsets = editorView.contentInset
        var rightMargin = (view.frame.maxX - editorView.frame.maxX)
        rightMargin -= view.safeAreaInsets.right

        scrollInsets.right = -rightMargin
        editorView.scrollIndicatorInsets = scrollInsets
    }

    func updateTitleHeight() {
        let layoutMargins = view.layoutMargins
        let insets = titleTextView.textContainerInset

        var titleWidth = titleTextView.bounds.width
        if titleWidth <= 0 {
            // Use the title text field's width if available, otherwise calculate it.
            titleWidth = view.frame.width - (insets.left + insets.right + layoutMargins.left + layoutMargins.right)
        }

        let sizeThatShouldFitTheContent = titleTextView.sizeThatFits(CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude))
        titleHeightConstraint.constant = max(sizeThatShouldFitTheContent.height, titleTextView.font!.lineHeight + insets.top + insets.bottom)

        titlePlaceholderLabel.isHidden = !titleTextView.text.isEmpty

        var contentInset = editorView.contentInset
        contentInset.top = (titleHeightConstraint.constant + separatorView.frame.height)
        editorView.contentInset = contentInset
        editorView.contentOffset = CGPoint(x: 0, y: -contentInset.top)
    }

    // MARK: - Configuration Methods
    override func updateViewConstraints() {
        updateTitlePosition()
        updateTitleHeight()
        super.updateViewConstraints()
    }

    private func configureConstraints() {

        titleHeightConstraint = titleTextView.heightAnchor.constraint(equalToConstant: ceil(titleTextView.font!.lineHeight))
        titleTopConstraint = titleTextView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        titlePlaceholderTopConstraint = titlePlaceholderLabel.topAnchor.constraint(equalTo: titleTextView.topAnchor, constant:0)
        titlePlaceholderLeadingConstraint = titlePlaceholderLabel.leadingAnchor.constraint(equalTo: titleTextView.leadingAnchor, constant: 0)
        updateTitlePosition()
        updateTitleHeight()

        let layoutGuide = view.readableContentGuide

        NSLayoutConstraint.activate([
            titleTextView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            titleTextView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            titleHeightConstraint,
            titleTopConstraint
            ])

        NSLayoutConstraint.activate([
            titlePlaceholderLeadingConstraint,
            titlePlaceholderLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            titlePlaceholderTopConstraint
            ])

        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor, constant: 0),
            separatorView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor, constant: 0),
            separatorView.topAnchor.constraint(equalTo: titleTextView.bottomAnchor, constant: 0),
            separatorView.heightAnchor.constraint(equalToConstant: separatorView.frame.height)
            ])

        NSLayoutConstraint.activate([
            editorView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            editorView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            ])
    }


    private func configureDefaultProperties(for textView: TextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.font = Constants.defaultContentFont
        textView.keyboardDismissMode = .interactive
        if #available(iOS 13.0, *) {
            textView.textColor = UIColor.label
            textView.defaultTextColor = UIColor.label
        } else {
            // Fallback on earlier versions
            textView.textColor = UIColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1)
            textView.defaultTextColor = UIColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1)
        }
        textView.linkTextAttributes = [.foregroundColor: UIColor(red: 0x01 / 255.0, green: 0x60 / 255.0, blue: 0x87 / 255.0, alpha: 1), NSAttributedString.Key.underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)]
    }

    private func configureDefaultProperties(htmlTextView textView: UITextView, accessibilityLabel: String) {
        textView.accessibilityLabel = accessibilityLabel
        textView.font = Constants.defaultContentFont
        textView.keyboardDismissMode = .interactive
        if #available(iOS 13.0, *) {
            textView.textColor = UIColor.label
            if let htmlStorage = textView.textStorage as? HTMLStorage {
                htmlStorage.textColor = UIColor.label
            }
        } else {
            // Fallback on earlier versions
            textView.textColor = UIColor(red: 0x1A/255.0, green: 0x1A/255.0, blue: 0x1A/255.0, alpha: 1)
        }
        textView.linkTextAttributes = [.foregroundColor: UIColor(red: 0x01 / 255.0, green: 0x60 / 255.0, blue: 0x87 / 255.0, alpha: 1), NSAttributedString.Key.underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue)]
    }

    private func registerAttachmentImageProviders() {
        let providers: [TextViewAttachmentImageProvider] = [
            GutenpackAttachmentRenderer(),
            SpecialTagAttachmentRenderer(),
            CommentAttachmentRenderer(font: Constants.defaultContentFont),
            HTMLAttachmentRenderer(font: Constants.defaultHtmlFont),
        ]

        for provider in providers {
            richTextView.registerAttachmentImageProvider(provider)
        }
    }

    // MARK: - Helpers

    @IBAction func toggleEditingMode() {
        formatBar.overflowToolbar(expand: true)
        editorView.toggleEditingMode()
    }
    
    // MARK: - Options VC
    
    private let formattingIdentifiersWithOptions: [FormattingIdentifier] = [.orderedlist, .unorderedlist, .p, .header1, .header2, .header3, .header4, .header5, .header6]
    
    private func formattingIdentifierHasOptions(_ formattingIdentifier: FormattingIdentifier) -> Bool {
        return formattingIdentifiersWithOptions.contains(formattingIdentifier)
    }

    // MARK: - Keyboard Handling

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: AnyObject],
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }

        refreshInsets(forKeyboardFrame: keyboardFrame)
        optionsTablePresenter.dismiss()
    }

    fileprivate func refreshInsets(forKeyboardFrame keyboardFrame: CGRect) {
        
        // The reason why we're converting the keyboard coordinates instead of just using
        // keyboardFrame.height, is that we need to make sure the insets take into account the
        // possibility that there could be other views on top or below the text view.
        // keyboardInset is basically the distance between the top of the keyboard
        // and the bottom of the text view.
        let localKeyboardOrigin = view.convert(keyboardFrame.origin, from: nil)
        let keyboardInset = max(view.frame.height - localKeyboardOrigin.y, 0)
        
        let contentInset = UIEdgeInsets(
            top: editorView.contentInset.top,
            left: 0,
            bottom: keyboardInset,
            right: 0)

        editorView.contentInset = contentInset
        updateScrollInsets()
    }


    func updateFormatBar() {
        guard let toolbar = richTextView.inputAccessoryView as? Aztec.FormatBar else {
            return
        }

        let identifiers: Set<FormattingIdentifier>
        if richTextView.selectedRange.length > 0 {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
        }

        toolbar.selectItemsMatchingIdentifiers(identifiers.map({ $0.rawValue }))
    }

    override var keyCommands: [UIKeyCommand] {
        if titleTextView.isFirstResponder {
            return [
                UIKeyCommand(input: "\t", modifierFlags: [], action: #selector(tabOnTitle))
            ]
        }
        
        if richTextView.isFirstResponder {
            return [ UIKeyCommand(title: NSLocalizedString("Bold", comment: "Discoverability title for bold formatting keyboard shortcut."), action:#selector(toggleBold), input:"B", modifierFlags: .command, propertyList: nil, alternates: []),
                     UIKeyCommand(title:NSLocalizedString("Italic", comment: "Discoverability title for italic formatting keyboard shortcut."), action:#selector(toggleItalic), input:"I", modifierFlags: .command ),
                     UIKeyCommand(title: NSLocalizedString("Strikethrough", comment:"Discoverability title for strikethrough formatting keyboard shortcut."), action:#selector(toggleStrikethrough), input:"S", modifierFlags: [.command]),
                     UIKeyCommand(title: NSLocalizedString("Underline", comment:"Discoverability title for underline formatting keyboard shortcut."), action:#selector(EditorDemoController.toggleUnderline(_:)), input:"U", modifierFlags: .command ),
                     UIKeyCommand(title: NSLocalizedString("Block Quote", comment: "Discoverability title for block quote keyboard shortcut."), action: #selector(toggleBlockquote), input:"Q", modifierFlags:[.command,.alternate]),
                     UIKeyCommand(title: NSLocalizedString("Insert Link", comment: "Discoverability title for insert link keyboard shortcut."), action:#selector(toggleLink), input:"K", modifierFlags:.command),
                     UIKeyCommand(title: NSLocalizedString("Insert Media", comment: "Discoverability title for insert media keyboard shortcut."), action:#selector(showImagePicker), input:"M", modifierFlags:[.command,.alternate]),
                     UIKeyCommand(title:NSLocalizedString("Bullet List", comment: "Discoverability title for bullet list keyboard shortcut."), action:#selector(toggleUnorderedList), input:"U", modifierFlags:[.command, .alternate]),
                     UIKeyCommand(title:NSLocalizedString("Numbered List", comment:"Discoverability title for numbered list keyboard shortcut."), action:#selector(toggleOrderedList), input:"O", modifierFlags:[.command, .alternate]),
                     UIKeyCommand(title:NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."), action:#selector(toggleEditingMode), input:"H", modifierFlags:[.command, .shift])
            ]
        } else if htmlTextView.isFirstResponder {
            return [UIKeyCommand(title:NSLocalizedString("Toggle HTML Source ", comment: "Discoverability title for HTML keyboard shortcut."), action:#selector(toggleEditingMode), input:"H", modifierFlags:[.command, .shift])
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

        if titleTextView.resignFirstResponder() {
            titleTextView.becomeFirstResponder()
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
        case richTextView:
            updateFormatBar()
        case titleTextView:
            updateTitleHeight()
        default:
            break
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        switch textView {
        case titleTextView:
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

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTitlePosition()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
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
        
        if !formattingIdentifierHasOptions(formattingIdentifier) {
            optionsTablePresenter.dismiss()
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
        case .code:
            toggleCode()
        default:
            break
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

    @objc func toggleCode() {
        richTextView.toggleCode(range: richTextView.selectedRange)
    }

    func insertHorizontalRuler() {
        richTextView.replaceWithHorizontalRuler(at: richTextView.selectedRange)
    }

    func toggleHeader(fromItem item: FormatBarItem) {
        guard !optionsTablePresenter.isOnScreen() else {
            optionsTablePresenter.dismiss()
            return
        }
        
        let options = Constants.headers.map { headerType -> OptionsTableViewOption in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: CGFloat(headerType.fontSize))
            ]

            let title = NSAttributedString(string: headerType.description, attributes: attributes)
            return OptionsTableViewOption(image: headerType.iconImage, title: title)
        }

        let selectedIndex = Constants.headers.firstIndex(of: headerLevelForSelectedText())
        let optionsTableViewController = OptionsTableViewController(options: options)
        optionsTableViewController.cellDeselectedTintColor = .gray
        
        optionsTablePresenter.present(
            optionsTableViewController,
            fromBarItem: item,
            selectedRowIndex: selectedIndex,
            onSelect: { [weak self] selected in
                guard let range = self?.richTextView.selectedRange else {
                    return
                }

                self?.richTextView.toggleHeader(Constants.headers[selected], range: range)
                self?.optionsTablePresenter.dismiss()
        })
    }

    func toggleList(fromItem item: FormatBarItem) {
        guard !optionsTablePresenter.isOnScreen() else {
            optionsTablePresenter.dismiss()
            return
        }
        
        let options = Constants.lists.map { (listType) -> OptionsTableViewOption in
            return OptionsTableViewOption(image: listType.iconImage, title: NSAttributedString(string: listType.description, attributes: [:]))
        }

        var index: Int? = nil
        if let listType = listTypeForSelectedText() {
            index = Constants.lists.firstIndex(of: listType)
        }
        
        let optionsTableViewController = OptionsTableViewController(options: options)
        optionsTableViewController.cellDeselectedTintColor = .gray

        optionsTablePresenter.present(
            optionsTableViewController,
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
                
                self?.optionsTablePresenter.dismiss()
        })
    }

    @objc func toggleUnorderedList() {
        richTextView.toggleUnorderedList(range: richTextView.selectedRange)
    }

    @objc func toggleOrderedList() {
        richTextView.toggleOrderedList(range: richTextView.selectedRange)
    }

    func changeRichTextInputView(to: UIView?) {
        if richTextView.inputView == to {
            return
        }

        richTextView.inputView = to
        richTextView.reloadInputViews()
    }

    func headerLevelForSelectedText() -> Header.HeaderType {
        var identifiers = Set<FormattingIdentifier>()
        if (richTextView.selectedRange.length > 0) {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
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
        var identifiers = Set<FormattingIdentifier>()
        if (richTextView.selectedRange.length > 0) {
            identifiers = richTextView.formattingIdentifiersSpanningRange(richTextView.selectedRange)
        } else {
            identifiers = richTextView.formattingIdentifiersForTypingAttributes()
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
        let target = richTextView.linkTarget(forRange: richTextView.selectedRange)
        linkTitle = richTextView.attributedText.attributedSubstring(from: linkRange).string
        let allowTextEdit = !richTextView.attributedText.containsAttachments(in: linkRange)
        showLinkDialog(forURL: linkURL, text: linkTitle, target: target, range: linkRange, allowTextEdit: allowTextEdit)
    }

    func insertMoreAttachment() {
        richTextView.replace(richTextView.selectedRange, withComment: Constants.moreAttachmentText)
    }

    func showLinkDialog(forURL url: URL?, text: String?, target: String?, range: NSRange, allowTextEdit: Bool = true) {

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
                                                preferredStyle:UIAlertController.Style.alert)
        alertController.view.accessibilityIdentifier = "linkModal"

        alertController.addTextField(configurationHandler: { [weak self]textField in
            textField.clearButtonMode = UITextField.ViewMode.always;
            textField.placeholder = NSLocalizedString("URL", comment:"URL text field placeholder");
            textField.keyboardType = .URL
            textField.textContentType = .URL
            textField.text = urlToUse?.absoluteString

            textField.addTarget(self,
                action:#selector(EditorDemoController.alertTextFieldDidChange),
            for:UIControl.Event.editingChanged)
            
            textField.accessibilityIdentifier = "linkModalURL"
            })

        if allowTextEdit {
            alertController.addTextField(configurationHandler: { textField in
                textField.clearButtonMode = UITextField.ViewMode.always
                textField.placeholder = NSLocalizedString("Link Text", comment:"Link text field placeholder")
                textField.isSecureTextEntry = false
                textField.autocapitalizationType = UITextAutocapitalizationType.sentences
                textField.autocorrectionType = UITextAutocorrectionType.default
                textField.spellCheckingType = UITextSpellCheckingType.default

                textField.text = text;

                textField.accessibilityIdentifier = "linkModalText"

                })
        }

        alertController.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = UITextField.ViewMode.always
            textField.placeholder = NSLocalizedString("Target", comment:"Link text field placeholder")
            textField.isSecureTextEntry = false
            textField.autocapitalizationType = UITextAutocapitalizationType.sentences
            textField.autocorrectionType = UITextAutocorrectionType.default
            textField.spellCheckingType = UITextSpellCheckingType.default

            textField.text = target;

            textField.accessibilityIdentifier = "linkModalTarget"

        })

        let insertAction = UIAlertAction(title:insertButtonTitle,
                                         style:UIAlertAction.Style.default,
                                         handler:{ [weak self]action in

                                            self?.richTextView.becomeFirstResponder()
                                            guard let textFields = alertController.textFields else {
                                                    return
                                            }
                                            let linkURLField = textFields[0]
                                            let linkTextField = textFields[1]
                                            let linkTargetField = textFields[2]
                                            let linkURLString = linkURLField.text
                                            var linkTitle = linkTextField.text
                                            let target = linkTargetField.text

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
                                                    self?.richTextView.setLink(url, title: title, target: target, inRange: range)
                                                }
                                            } else {
                                                self?.richTextView.setLink(url, target: target, inRange: range)
                                            }
                                            })
        
        insertAction.accessibilityLabel = "insertLinkButton"

        let removeAction = UIAlertAction(title:removeButtonTitle,
                                         style:UIAlertAction.Style.destructive,
                                         handler:{ [weak self] action in
                                            self?.richTextView.becomeFirstResponder()
                                            self?.richTextView.removeLink(inRange: range)
            })

        let cancelAction = UIAlertAction(title: cancelButtonTitle,
                                         style:UIAlertAction.Style.cancel,
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

        present(alertController, animated:true, completion:nil)
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
    
    @objc func tabOnTitle() {
        if editorView.becomeFirstResponder() {
            editorView.selectedTextRange = editorView.htmlTextView.textRange(from: editorView.htmlTextView.endOfDocument, to: editorView.htmlTextView.endOfDocument)
        }
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

        if #available(iOS 13.0, *) {
            toolbar.backgroundColor = UIColor.systemGroupedBackground
            toolbar.tintColor = UIColor.secondaryLabel
            toolbar.highlightedTintColor = UIColor.systemBlue
            toolbar.selectedTintColor = UIColor.systemBlue
            toolbar.disabledTintColor = .systemGray4
            toolbar.dividerTintColor = UIColor.separator
        } else {
            toolbar.tintColor = .gray
            toolbar.highlightedTintColor = .blue
            toolbar.selectedTintColor = view.tintColor
            toolbar.disabledTintColor = .lightGray
            toolbar.dividerTintColor = .gray
        }

        toolbar.overflowToggleIcon = UIImage.init(systemName: "ellipsis")!
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
            makeToolbarButton(identifier: .code),
            makeToolbarButton(identifier: .horizontalruler),
            makeToolbarButton(identifier: .more),
            makeToolbarButton(identifier: .sourcecode)
        ]
    }

}

extension EditorDemoController: UINavigationControllerDelegate
{
}

// MARK: - UIImagePickerControllerDelegate

extension EditorDemoController: UIImagePickerControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        dismiss(animated: true, completion: nil)
        richTextView.becomeFirstResponder()
        guard let mediaType =  info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as? String else {
            return
        }
        let typeImage = kUTTypeImage as String
        let typeMovie = kUTTypeMovie as String

        switch mediaType {
        case typeImage:
            guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
                return
            }

            // Insert Image + Reclaim Focus
            mediaInserter.insertImage(image)

        case typeMovie:
            guard let videoURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL else {
                return
            }
            mediaInserter.insertVideo(videoURL)
        default:
            print("Media type not supported: \(mediaType)")
        }
    }
}

// MARK: - Constants
//

extension EditorDemoController {

    static var tintedMissingImage: UIImage = {
        if #available(iOS 13.0, *) {
            return UIImage.init(systemName: "photo")!.withTintColor(.label)
        } else {
            // Fallback on earlier versions
            return UIImage.init(systemName: "photo")!
        }
    }()

    struct Constants {
        static let defaultContentFont   = UIFont.systemFont(ofSize: 14)
        static let defaultHtmlFont      = UIFont.systemFont(ofSize: 24)
        static let defaultMissingImage  = tintedMissingImage
        static let formatBarIconSize    = CGSize(width: 20.0, height: 20.0)
        static let headers              = [Header.HeaderType.none, .h1, .h2, .h3, .h4, .h5, .h6]
        static let lists                = [TextList.Style.unordered, .ordered]        
        static let moreAttachmentText   = "more"
        static let titleInsets          = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        static var mediaMessageAttributes: [NSAttributedString.Key: Any] {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                                                            .paragraphStyle: paragraphStyle,
                                                            .foregroundColor: UIColor.white]
            return attributes
        }
    }    
}

extension UIImage {

    static func systemImage(_ name: String) -> UIImage {
        guard let image = UIImage(systemName: name) else {
            assertionFailure("Missing system image: \(name)")
            return UIImage()
        }

        return image
    }
}

extension FormattingIdentifier {

    var iconImage: UIImage {

        switch(self) {
        case .media:
            return UIImage.systemImage("plus.circle")
        case .p:
            return UIImage.systemImage("textformat.size")
        case .bold:
            return UIImage.systemImage("bold")
        case .italic:
            return UIImage.systemImage("italic")
        case .underline:
            return UIImage.systemImage("underline")
        case .strikethrough:
            return UIImage.systemImage("strikethrough")
        case .blockquote:
            return UIImage.systemImage("text.quote")
        case .orderedlist:
            return UIImage.systemImage("list.number")
        case .unorderedlist:
            return UIImage.systemImage("list.bullet")
        case .link:
            return UIImage.systemImage("link")
        case .horizontalruler:
            return UIImage.systemImage("minus")
        case .sourcecode:
            return UIImage.systemImage("chevron.left.slash.chevron.right")
        case .more:
            return UIImage.systemImage("textformat.abc.dottedunderline")
        case .header1:
            return UIImage.systemImage("textformat.size")
        case .header2:
            return UIImage.systemImage("textformat.size")
        case .header3:
            return UIImage.systemImage("textformat.size")
        case .header4:
            return UIImage.systemImage("textformat.size")
        case .header5:
            return UIImage.systemImage("textformat.size")
        case .header6:
            return UIImage.systemImage("textformat.size")
        case .code:
            return UIImage.systemImage("textbox")
        default:
            return UIImage.systemImage("info")
        }
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
        case .code:
            return "formatToolbarCode"
        default:
            return ""
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
        case .code:
            return NSLocalizedString("Code", comment: "Accessibility label for selecting code style button on the formatting toolbar.")
        default:
            return ""
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
