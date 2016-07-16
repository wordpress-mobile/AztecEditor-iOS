import Foundation
import UIKit


public class AztecFormatBar: UIToolbar
{
    static let buttonFrame = CGRect(x: 0, y: 0, width: 44.0, height: 44.0)

    public var formatter: AztecFormatBarDelegate?

    lazy var boldButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_bold")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleBoldAction(_:)))
        button.identifier = AztecFormattingIdentifier.Bold.rawValue
        self.applyButtonStyle(button)
        return button
    }()


    lazy var italicButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_italic")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleItalicAction(_:)))
        button.identifier = AztecFormattingIdentifier.Italic.rawValue
        self.applyButtonStyle(button)
        return button
    }()


    lazy var underlineButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_underline")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleUnderlineAction(_:)))
        button.identifier = AztecFormattingIdentifier.Underline.rawValue
        self.applyButtonStyle(button)
        return button
    }()


    lazy var strikeButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_strikethrough")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleStrikethroughAction(_:)))
        button.identifier = AztecFormattingIdentifier.Strikethrough.rawValue
        self.applyButtonStyle(button)
        return button
    }()


    lazy var orderedListButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_ol")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleOrderedListAction(_:)))
        button.identifier = AztecFormattingIdentifier.Orderedlist.rawValue
        self.applyButtonStyle(button)
        return button
    }()


    lazy var unorderedListButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_ul")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleUnorderedListAction(_:)))
        button.identifier = AztecFormattingIdentifier.Unorderedlist.rawValue
        self.applyButtonStyle(button)
        return button
    }()


    lazy var blockquoteButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_quote")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleBlockquoteAction(_:)))
        button.identifier = AztecFormattingIdentifier.Blockquote.rawValue
        self.applyButtonStyle(button)
        return button
    }()


    lazy var linkButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_link")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleLinkAction(_:)))
        button.identifier = AztecFormattingIdentifier.Link.rawValue
        self.applyButtonStyle(button)
        return button
    }()


    lazy var mediaButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_media")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleMediaAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    public var enabled = true {
        didSet {
            guard let items = items else {
                return
            }
            for item in items {
                if let barItem = item as? AztecFormatBarItem {
                    barItem.enabled = enabled
                }
            }
        }
    }


    // MARK: - Lifecycle Methods


    init() {
        super.init(frame: CGRectZero)
        setupButtons()
    }


    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButtons()
    }


    // MARK: - Setup


    func getImageNamed(named: String) -> UIImage {
        let bundle = NSBundle(forClass: self.dynamicType)
        let image = UIImage(named: named, inBundle: bundle, compatibleWithTraitCollection: nil)
        return image!.imageWithRenderingMode(.AlwaysTemplate)
    }


    func setupButtons() {
        let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        items = [
            flex,
            mediaButton,
            flex,
            boldButton,
            flex,
            italicButton,
            flex,
            underlineButton,
            flex,
            blockquoteButton,
            flex,
            unorderedListButton,
            flex,
            orderedListButton,
            flex,
            linkButton,
            flex,
        ]
    }


    // MARK: - Styles


    func applyButtonStyle(button: AztecFormatBarItem) {
        button.tintColor = UIColor.grayColor()
        button.selectedTintColor = UIColor.darkGrayColor()
        button.highlightedTintColor = UIColor.blueColor()
        button.disabledTintColor = UIColor.lightGrayColor()
    }


    ///
    ///
    public func selectItemsMatchingIdentifiers(identifiers: [String]) {
        guard let items = items else {
            return
        }
        for item in items {
            if let barItem = item as? AztecFormatBarItem, let identifier = barItem.identifier {
                barItem.selected = identifiers.contains(identifier)
            }
        }
    }


    // MARK: - Actions


    func handleBoldAction(sender: AztecFormatBarItem) {
        formatter?.toggleBold()
    }


    func handleItalicAction(sender: AztecFormatBarItem) {
        formatter?.toggleItalic()
    }


    func handleUnderlineAction(sender: AztecFormatBarItem) {
        formatter?.toggleUnderline()
    }


    func handleStrikethroughAction(sender: AztecFormatBarItem) {
        formatter?.toggleStrikethrough()
    }


    func handleOrderedListAction(sender: AztecFormatBarItem) {
        formatter?.toggleOrderedList()
    }


    func handleUnorderedListAction(sender: AztecFormatBarItem) {
        formatter?.toggleUnorderedList()
    }


    func handleBlockquoteAction(sender: AztecFormatBarItem) {
        formatter?.toggleBlockquote()
    }


    func handleLinkAction(sender: AztecFormatBarItem) {
        formatter?.toggleLink()
    }
    
    
    func handleMediaAction(sender: AztecFormatBarItem) {
        formatter?.insertImage()
    }

}
