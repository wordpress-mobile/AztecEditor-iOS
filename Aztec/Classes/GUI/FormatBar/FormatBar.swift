import Foundation
import UIKit


// MARK: - FormatBar
//
open class FormatBar: UIView {

    /// Format Bar's Delegate
    ///
    open weak var formatter: FormatBarDelegate?


    /// Container ScrollView
    ///
    fileprivate let scrollView = UIScrollView()


    /// StackView embedded within the ScrollView
    ///
    fileprivate let scrollableStackView = UIStackView()


    /// Fixed StackView
    ///
    fileprivate let fixedStackView = UIStackView()


    /// FormatBarItems to be embedded within the Scrollable StackView
    ///
    open var scrollableItems = [FormatBarItem]() {
        willSet {
            scrollableStackView.removeArrangedSubviews(scrollableItems)
        }
        didSet {
            configure(items: scrollableItems)
            scrollableStackView.addArrangedSubviews(scrollableItems)
        }
    }


    /// FormatBarItems to be embedded within the Fixed StackView
    ///
    open var fixedItems = [FormatBarItem]() {
        willSet {
            fixedStackView.removeArrangedSubviews(fixedItems)
        }
        didSet {
            configure(items: fixedItems)
            fixedStackView.addArrangedSubviews(fixedItems)
        }
    }


    /// Returns the collection of all of the FormatBarItem's (Scrollable + Fixed)
    ///
    private var items: [FormatBarItem] {
        return scrollableItems + fixedItems
    }

    
    /// Tint Color
    ///
    override open var tintColor: UIColor? {
        didSet {
            for item in items {
                item.tintColor = tintColor
            }
        }
    }


    /// Tint Color to be applied over Selected Items
    ///
    open var selectedTintColor: UIColor? {
        didSet {
            for item in items {
                item.selectedTintColor = selectedTintColor
            }
        }
    }


    /// Tint Color to be applied over Highlighted Items
    ///
    open var highlightedTintColor: UIColor? {
        didSet {
            for item in items {
                item.highlightedTintColor = highlightedTintColor
            }
        }
    }


    /// Tint Color to be applied over Disabled Items
    ///
    open var disabledTintColor: UIColor? {
        didSet {
            for item in items {
                item.disabledTintColor = disabledTintColor
            }
        }
    }


    /// Enables or disables all of the Format Bar Items
    ///
    open var enabled = true {
        didSet {
            for item in items {
                item.isEnabled = enabled
            }
        }
    }


    /// Top Border's Separator Color
    ///
    open var topBorderColor = UIColor.darkGray



    // MARK: - Initializers


    public init() {
        super.init(frame: .zero)

        configure(scrollView: scrollView)
        configure(stackView: scrollableStackView)
        configure(stackView: fixedStackView)

        scrollView.addSubview(scrollableStackView)
        addSubview(scrollView)
        addSubview(fixedStackView)

        configureConstraints()
    }


    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }



    // MARK: - Drawing!

    open override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        // Setup the Context
        let scale = UIScreen.main.scale
        let lineWidthInPoints = Constants.topBorderHeightInPixels / scale

        context.clear(rect)
        context.setShouldAntialias(false)
        context.setLineWidth(lineWidthInPoints)

        // Background
        let bgColor = backgroundColor ?? .white
        bgColor.setFill()
        context.fill(rect)

        // Top Separator
        topBorderColor.setStroke()

        context.move(to: CGPoint(x: 0, y: lineWidthInPoints))
        context.addLine(to: CGPoint(x: bounds.maxX, y: lineWidthInPoints))
        context.strokePath()
    }


    // MARK: - Styles

    /// Selects all of the FormatBarItems matching a collection of Identifiers
    ///
    open func selectItemsMatchingIdentifiers(_ identifiers: [FormattingIdentifier]) {
        for item in items {
            if let identifier = item.identifier {
                item.isSelected = identifiers.contains(identifier)
            }
        }
    }


    // MARK: - Actions

    @IBAction func handleButtonAction(_ sender: FormatBarItem) {
        formatter?.handleActionForIdentifier(sender.identifier!)
    }
}



// MARK: - Private Helpers
//
private extension FormatBar {

    /// Detaches a given collection of FormatBarItem's
    ///
    func detach(items: [FormatBarItem]) {
        for item in items {
            item.removeFromSuperview()
        }
    }


    /// Sets up a given collection of FormatBarItem's1
    ///
    func configure(items: [FormatBarItem]) {
        for item in items {
            configure(item: item)
        }
    }


    /// Sets up a given FormatBarItem
    ///
    func configure(item: FormatBarItem) {
        item.tintColor = tintColor
        item.selectedTintColor = selectedTintColor
        item.highlightedTintColor = highlightedTintColor
        item.disabledTintColor = disabledTintColor

        item.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
    }


    /// Sets up a given StackView
    ///
    func configure(stackView: UIStackView) {
        stackView.axis = .horizontal
        stackView.spacing = Constants.stackViewSpacing
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }


    /// Sets up the ScrollView
    ///
    func configure(scrollView: UIScrollView) {
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
    }


    /// Sets up the Constraints
    ///
    func configureConstraints() {
        let fixedInsets = Constants.fixedStackViewInsets
        let scrollableInsets = Constants.scrollableStackViewInsets

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

        NSLayoutConstraint.activate([
            fixedStackView.leadingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: fixedInsets.left),
            fixedStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1 * fixedInsets.right),
            fixedStackView.topAnchor.constraint(equalTo: topAnchor),
            fixedStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            scrollableStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: scrollableInsets.left),
            scrollableStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -1 * scrollableInsets.right),
            scrollableStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollableStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollableStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            scrollableStackView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor, constant: -1 * (scrollableInsets.left + scrollableInsets.right))
            ])
    }
}


// MARK: - Private Constants
//
private extension FormatBar {

    struct Constants {
        static let fixedStackViewInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 10)
        static let scrollableStackViewInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        static let stackViewSpacing = CGFloat(7)
        static let topBorderHeightInPixels = CGFloat(1)
    }
}
