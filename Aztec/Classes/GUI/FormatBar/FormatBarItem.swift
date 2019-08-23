import Foundation
import UIKit


// MARK: - FormatBarItem
//
open class FormatBarItem: UIButton {

    /// Identifier for this item. It's recommended to use a custom String enum
    /// to encapsulate the values used here.
    ///
    open var identifier: String?


    /// Tint Color to be applied whenever the button is selected
    ///
    open var selectedTintColor: UIColor? {
        didSet {
            updateTintColor()
        }
    }


    /// Tint Color to be applied whenever the button is highlighted
    ///
    open var highlightedTintColor: UIColor? {
        didSet {
            updateTintColor()
        }
    }


    /// Tint Color to be applied whenever the button is disabled
    ///
    open var disabledTintColor: UIColor? {
        didSet {
            updateTintColor()
        }
    }


    /// Tint Color to be applied to the "Normal" State
    ///
    open var normalTintColor: UIColor? {
        didSet {
            updateTintColor()
        }
    }


    /// Enabled Listener: Update Tint Colors, as needed
    ///
    open override var isEnabled: Bool {
        didSet {
            updateTintColor()
        }
    }


    /// Highlight Listener: Update Tint Colors, as needed
    ///
    open override var isHighlighted: Bool {
        didSet {
            updateTintColor()
        }
    }

    
    /// Selection Listener: Update Tint Colors, as needed
    ///
    open override var isSelected: Bool {
        didSet {
            updateTintColor()
        }
    }


    // MARK: - Icons

    /// A list of alternative icons that can be switched out for
    /// this item's default icon if their identifiers are detected
    ///
    public var alternativeIcons: [String: UIImage]? = nil

    /// Switch out this item's icon for the icon that matches the specified identifier
    ///
    public func useAlternativeIconForIdentifier(_ identifier: String) {
        if let icon = alternativeIcons?[identifier] {
            setImage(icon, for: .normal)
        }
    }

    /// Reset this item's icon back to default
    ///
    public func resetIcon() {
        setImage(originalIcon, for: .normal)
    }

    private var originalIcon: UIImage

    // MARK: - Lifecycle

    public convenience init(image: UIImage, identifier: String? = nil) {
        let defaultFrame = CGRect(x: 0, y: 0, width: FormatBar.Constants.defaultButtonWidth, height: FormatBar.Constants.defaultButtonHeight)
        self.init(image: image, frame: defaultFrame)
        self.identifier = identifier
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: FormatBar.Constants.defaultButtonWidth,
                      height: FormatBar.Constants.defaultButtonHeight)
    }

    public init(image: UIImage, frame: CGRect) {
        self.originalIcon = image

        super.init(frame: frame)
        self.setImage(image, for: UIControl.State())
        self.adjustsImageWhenDisabled = false
        self.adjustsImageWhenHighlighted = false
    }


    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Actions

    private func updateTintColor() {
        if state.contains(.disabled) {
            tintColor = disabledTintColor
            return
        }

        if state.contains(.highlighted) {
            tintColor = highlightedTintColor
            return
        }

        if state.contains(.selected) {
            tintColor = selectedTintColor
            return
        }

        tintColor = normalTintColor
    }
}

class FormatBarDividerItem: UIView {
    init() {
        super.init(frame: .zero)

        layoutMargins = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// You can modify the divider item's layout margins to
    override var layoutMargins: UIEdgeInsets {
        didSet {
            if layoutMargins != oldValue {
                invalidateIntrinsicContentSize()
                setNeedsLayout()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 1.0, height: FormatBar.Constants.defaultButtonHeight - layoutMargins.top - layoutMargins.bottom)
    }
}
