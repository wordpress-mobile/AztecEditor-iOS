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
    var selectedTintColor: UIColor? {
        didSet {
            updateTintColor()
        }
    }


    /// Tint Color to be applied whenever the button is highlighted
    ///
    var highlightedTintColor: UIColor? {
        didSet {
            updateTintColor()
        }
    }


    /// Tint Color to be applied whenever the button is disabled
    ///
    var disabledTintColor: UIColor? {
        didSet {
            updateTintColor()
        }
    }


    /// Tint Color to be applied to the "Normal" State
    ///
    var normalTintColor: UIColor? {
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
        let defaultFrame = CGRect(x: 0, y: 0, width: 44, height: 44)
        self.init(image: image, frame: defaultFrame)
        self.identifier = identifier
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: 44.0, height: 44.0)
    }

    public init(image: UIImage, frame: CGRect) {
        self.originalIcon = image

        super.init(frame: frame)
        self.setImage(image, for: UIControlState())
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
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 1.0, height: 44.0)
    }
}
