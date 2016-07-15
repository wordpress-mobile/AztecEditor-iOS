import Foundation
import UIKit


public class AztecFormatBar: UIToolbar
{
    static let buttonFrame = CGRect(x: 0, y: 0, width: 44.0, height: 44.0)


    lazy var boldButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_bold")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleBoldAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    lazy var italicButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_italic")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleItalicAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    lazy var underlineButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_underline")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleUnderlineAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    lazy var orderedListButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_ol")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleOrderedListAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    lazy var unorderedListButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_ul")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleUnorderedListAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    lazy var blockquoteButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_quote")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleBlockquoteAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    lazy var linkButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_link")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleLinkAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    lazy var mediaButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_media")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleMediaAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    lazy var htmlButton: AztecFormatBarItem = {
        let image = self.getImageNamed("icon_format_html")
        let button = AztecFormatBarItem(image: image, frame: buttonFrame, target: self, action: #selector(self.dynamicType.handleHtmlAction(_:)))
        self.applyButtonStyle(button)
        return button
    }()


    public var enabled = true {
        didSet {
            guard let _ = items else {
                return
            }
            for item in items! {
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
//        let fixed = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        items = [
            flex,
            mediaButton,
            flex,
            boldButton,
            flex,
            italicButton,
            flex,
            blockquoteButton,
            flex,
            unorderedListButton,
            flex,
            orderedListButton,
            flex,
            linkButton,
            flex,
            htmlButton,
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
    public func selectItemsMatchingStyles(styles: [String]) {
        // TODO: Should be called whenever the TextView's selectedRange changes.
    }


    // MARK: - Actions


    func handleBoldAction(sender: AztecFormatBarItem) {
        print("b")
    }


    func handleItalicAction(sender: AztecFormatBarItem) {
        print("i")
    }


    func handleUnderlineAction(sender: AztecFormatBarItem) {
        print("u")
    }


    func handleOrderedListAction(sender: AztecFormatBarItem) {
        print("ol")
    }


    func handleUnorderedListAction(sender: AztecFormatBarItem) {
        print("ul")
    }


    func handleBlockquoteAction(sender: AztecFormatBarItem) {
        print("blockquote")
    }


    func handleLinkAction(sender: AztecFormatBarItem) {
        print("a")
    }
    
    
    func handleMediaAction(sender: AztecFormatBarItem) {
        print("img")
    }


    func handleHtmlAction(sender: AztecFormatBarItem) {
        print("html")
    }
}
