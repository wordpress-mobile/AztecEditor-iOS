import Foundation
import UIKit


open class FormatBarItem: UIButton {

    var selectedTintColor: UIColor?
    var highlightedTintColor: UIColor?
    var disabledTintColor: UIColor?
    var normalTintColor: UIColor?

    open var identifier: FormattingIdentifier?



    override open var tintColor: UIColor? {
        didSet {
            normalTintColor = tintColor
        }
    }


    open override var isEnabled: Bool {
        didSet {
            updateTintColor()
        }
    }


    open override var isHighlighted: Bool {
        didSet {
            updateTintColor()
        }
    }


    open override var isSelected: Bool {
        didSet {
            updateTintColor()
        }
    }



    // MARK: - Lifecycle

    public convenience init(image: UIImage, identifier: FormattingIdentifier) {
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

    func updateTintColor() {
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
