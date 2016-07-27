import Foundation
import UIKit



public class FormatBarItem: UIBarButtonItem
{

    public var identifier: String?


    private var button: AztecFormatBarButton? {
        return customView as? AztecFormatBarButton
    }


    override public var tintColor: UIColor? {
        didSet {
            button?.normalTintColor = tintColor
            button?.tintColor = tintColor
        }
    }


    public var selectedTintColor: UIColor? {
        get {
            return button?.selectedTintColor
        }
        set {
            button?.selectedTintColor = newValue
        }
    }


    public var highlightedTintColor: UIColor? {
        get {
            return button?.highlightedTintColor
        }
        set {
            button?.highlightedTintColor = newValue
        }
    }


    public var disabledTintColor: UIColor? {
        get {
            return button?.disabledTintColor
        }
        set {
            button?.disabledTintColor = newValue
        }
    }


    public override var enabled: Bool {
        didSet {
            button?.enabled = enabled
        }
    }


    public var selected: Bool {
        get {
            return button?.selected ?? false
        }
        set {
            button?.selected = newValue
        }
    }


    // MARK: - Lifecycle

    public convenience init(image: UIImage, identifier: String) {
        let defaultFrame = CGRect(x: 0, y: 0, width: 44, height: 44)
        self.init(image: image, frame: defaultFrame, target: nil, action: nil)
        self.identifier = identifier
    }


    init(image: UIImage, frame: CGRect, target: AnyObject?, action: Selector) {
        super.init()

        self.target = target
        self.action = action

        let button = AztecFormatBarButton(type: .Custom)
        button.frame = frame
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(self.dynamicType.handleButtonTapped(_:)), forControlEvents: .TouchUpInside)
        button.adjustsImageWhenDisabled = false
        button.adjustsImageWhenHighlighted = false

        style = .Plain
        customView = button
    }


    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Actions

    func handleButtonTapped(sender: UIButton) {
        target?.performSelector(action, withObject: self)
    }

}


class AztecFormatBarButton: UIButton
{

    var selectedTintColor: UIColor?
    var highlightedTintColor: UIColor?
    var disabledTintColor: UIColor?
    var normalTintColor: UIColor?


    override var selected: Bool {
        didSet {
            updateTintColor()
        }
    }


    override var highlighted: Bool {
        didSet {
            updateTintColor()
        }
    }


    override var enabled: Bool {
        didSet {
            updateTintColor()
        }
    }


    func updateTintColor() {
        if state.contains(.Disabled) {
            tintColor = disabledTintColor
            return
        }

        if state.contains(.Highlighted) {
            tintColor = highlightedTintColor
            return
        }

        if state.contains(.Selected) {
            tintColor = selectedTintColor
            return
        }

        tintColor = normalTintColor
    }

}
