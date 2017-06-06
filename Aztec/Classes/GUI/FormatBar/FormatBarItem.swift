import Foundation
import UIKit


// MARK: - FormatBarItem
//
open class FormatBarItem: UIButton {

    /// Formatting Identifier
    ///
    open var identifier: FormattingIdentifier?


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



    // MARK: - Lifecycle

    public convenience init(image: UIImage, identifier: FormattingIdentifier? = nil) {
        let defaultFrame = CGRect(x: 0, y: 0, width: 44, height: 44)
        self.init(image: image, frame: defaultFrame)
        self.identifier = identifier
    }


    public init(image: UIImage, frame: CGRect) {
        super.init(frame: frame)
        self.setImage(image, for: UIControlState())
        self.adjustsImageWhenDisabled = true
        self.adjustsImageWhenHighlighted = true
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
