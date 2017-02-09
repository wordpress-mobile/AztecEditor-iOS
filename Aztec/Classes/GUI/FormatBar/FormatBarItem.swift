import Foundation
import UIKit



open class FormatBarItem: UIBarButtonItem
{

    open var identifier: FormattingIdentifier?


    fileprivate var button: AztecFormatBarButton? {
        return customView as? AztecFormatBarButton
    }


    override open var tintColor: UIColor? {
        didSet {
            button?.normalTintColor = tintColor
            button?.tintColor = tintColor
        }
    }


    open var selectedTintColor: UIColor? {
        get {
            return button?.selectedTintColor
        }
        set {
            button?.selectedTintColor = newValue
        }
    }


    open var highlightedTintColor: UIColor? {
        get {
            return button?.highlightedTintColor
        }
        set {
            button?.highlightedTintColor = newValue
        }
    }


    open var disabledTintColor: UIColor? {
        get {
            return button?.disabledTintColor
        }
        set {
            button?.disabledTintColor = newValue
        }
    }


    open override var isEnabled: Bool {
        didSet {
            button?.isEnabled = isEnabled
        }
    }


    open var selected: Bool {
        get {
            return button?.isSelected ?? false
        }
        set {
            button?.isSelected = newValue
        }
    }


    // MARK: - Lifecycle

    public convenience init(image: UIImage, identifier: FormattingIdentifier) {
        let defaultFrame = CGRect(x: 0, y: 0, width: 44, height: 44)
        self.init(image: image, frame: defaultFrame, target: nil, action: nil)
        self.identifier = identifier
    }


    init(image: UIImage, frame: CGRect, target: AnyObject?, action: Selector?) {
        super.init()

        self.target = target
        self.action = action

        let button = AztecFormatBarButton(type: .custom)
        button.frame = frame
        button.setImage(image, for: UIControlState())
        button.addTarget(self, action: #selector(type(of: self).handleButtonTapped(_:)), for: .touchUpInside)
        button.adjustsImageWhenDisabled = true
        button.adjustsImageWhenHighlighted = true

        style = .plain
        customView = button
    }


    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Actions

    func handleButtonTapped(_ sender: UIButton) {
        guard let target = target,
            let action = action else {
            return
        }
        
        _ = target.perform(action, with: self)
    }

}


class AztecFormatBarButton: UIButton
{

    var selectedTintColor: UIColor?
    var highlightedTintColor: UIColor?
    var disabledTintColor: UIColor?
    var normalTintColor: UIColor?


    override var isSelected: Bool {
        didSet {
            updateTintColor()
        }
    }


    override var isHighlighted: Bool {
        didSet {
            updateTintColor()
        }
    }


    override var isEnabled: Bool {
        didSet {
            updateTintColor()
        }
    }


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
