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


    /// Top dividing line
    ///
    fileprivate let topDivider = UIView()


    /// FormatBarItems to be displayed when the bar is in its default collapsed state.
    /// Each sub-array of items will be divided into a separate section in the bar.
    ///
    open var defaultItems = [[FormatBarItem]]() {
        didSet {
            let allItems = defaultItems.flatMap({ $0 })

            configure(items: allItems)

            populateItems()
        }
    }


    /// Extra FormatBarItems to be displayed when the bar is in its expanded state
    ///
    open var overflowItems = [FormatBarItem]() {
        didSet {
            configure(items: overflowItems)

            populateItems()

            setOverflowItemsVisible(false, animated: false)

            let hasOverflowItems = !overflowItems.isEmpty
            overflowToggleItem.isHidden = !hasOverflowItems
        }
    }


    /// FormatBarItem used to toggle the bar's expanded state
    ///
    fileprivate lazy var overflowToggleItem: FormatBarItem = {
        let item = FormatBarItem(image: UIImage(), identifier: nil)
        self.configureStylesFor(item)

        item.addTarget(self, action: #selector(handleToggleButtonAction), for: .touchUpInside)

        return item
    }()


    /// The icon to show on the overflow toggle button
    ///
    open var overflowToggleIcon: UIImage? {
        set {
            overflowToggleItem.setImage(newValue, for: .normal)
        }
        get {
            return overflowToggleItem.image(for: .normal)
        }
    }


    /// Returns the collection of all of the FormatBarItems
    ///
    private var items: [FormatBarItem] {
        return scrollableStackView.arrangedSubviews.filter({ $0 is FormatBarItem }) as! [FormatBarItem]
    }

    /// Returns all of the dividers (including the top divider) in the bar
    ///
    private var dividers: [UIView] {
        return scrollableStackView.arrangedSubviews.filter({ !($0 is FormatBarItem) }) + [topDivider]
    }

    /// Returns true if any of the overflow items in the bar are currently hidden
    ///
    private var overflowItemsHidden: Bool {
        if let _ = scrollableStackView.arrangedSubviews.first(where: { $0.isHidden }) {
            return true
        }

        return false
    }

    
    /// Tint Color
    ///
    override open var tintColor: UIColor? {
        didSet {
            for item in items {
                item.normalTintColor = tintColor
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


    /// Tint Color to be applied to dividers
    ///
    open var dividerTintColor: UIColor? {
        didSet {
            for divider in dividers {
                divider.backgroundColor = dividerTintColor
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


    /// Bounds Change Observer
    ///
    override open var bounds: CGRect {
        didSet {
            // Note: Under certain conditions, frame.didSet might get called instead of bounds.didSet.
            // We're observing both for that reason!
            refreshScrollingLock()
        }
    }


    /// Bounds Change Observer
    ///
    override open var frame: CGRect {
        didSet {
            // Note: Under certain conditions, frame.didSet might get called instead of bounds.didSet.
            // We're observing both for that reason!
            refreshScrollingLock()
        }
    }


    // MARK: - Initializers


    public init() {
        super.init(frame: .zero)
        backgroundColor = .white

        configure(scrollView: scrollView)
        configureScrollableStackView()

        addSubview(scrollView)
        scrollView.addSubview(scrollableStackView)

        topDivider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topDivider)

        overflowToggleItem.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overflowToggleItem)

        configureConstraints()
    }


    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }


    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshScrollingLock()
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
        guard let identifier = sender.identifier else { return }

        formatter?.handleActionForIdentifier(identifier)
    }

    @IBAction func handleToggleButtonAction(_ sender: FormatBarItem) {
        let shouldExpand = overflowItemsHidden

        let direction: OverflowToggleAnimationDirection = shouldExpand ? .vertical : .horizontal

        setOverflowItemsVisible(shouldExpand)

        rotateOverflowToggleItem(direction, animated: true)

        refreshScrollingLock()
    }

    private func setOverflowItemsVisible(_ visible: Bool, animated: Bool = true) {
        // Animate backwards if we're disappearing
        let items = visible ? overflowItems : overflowItems.reversed()

        let toggleVisibility = {
            items.forEach({ $0.isHidden = !visible })
        }

        // Currently only doing the pop animation for appearance
        if animated && visible {
            UIView.animate(withDuration: Animations.durationLong, animations: toggleVisibility)

            for (index, item) in items.enumerated() {
                animate(item: item, visible: visible, withDelay: Double(index) * Animations.itemPop.interItemAnimationDelay)
            }
        } else {
            toggleVisibility()
        }
    }
}


// MARK: - Configuration Helpers
//
private extension FormatBar {

    /// Populates the bar with the combined default and overflow items.
    /// Overflow items will be hidden by default.
    ///
    func populateItems() {
        scrollableStackView.removeArrangedSubviews(scrollableStackView.arrangedSubviews)

        for items in defaultItems {
            scrollableStackView.addArrangedSubviews(items)

            if let last = defaultItems.last,
                items != last {
                addDivider()
            }
        }

        scrollableStackView.addArrangedSubviews(overflowItems)
    }

    /// Inserts a divider into the bar.
    ///
    func addDivider() {
        let divider = FormatBarDividerItem()
        divider.backgroundColor = dividerTintColor
        scrollableStackView.addArrangedSubview(divider)
    }


    /// Sets up a given collection of FormatBarItem's
    ///
    func configure(items: [FormatBarItem]) {
        for item in items {
            configure(item: item)
        }
    }


    /// Sets up a given FormatBarItem
    ///
    func configure(item: FormatBarItem) {
        configureStylesFor(item)

        item.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
    }

    func configureStylesFor(_ item: FormatBarItem) {
        item.tintColor = tintColor
        item.selectedTintColor = selectedTintColor
        item.highlightedTintColor = highlightedTintColor
        item.disabledTintColor = disabledTintColor
    }


    /// Sets up the scrollable StackView
    ///
    func configureScrollableStackView() {
        scrollableStackView.axis = .horizontal
        scrollableStackView.spacing = Constants.stackViewCompactSpacing
        scrollableStackView.alignment = .center
        scrollableStackView.distribution = .equalSpacing
        scrollableStackView.translatesAutoresizingMaskIntoConstraints = false
    }


    /// Sets up the ScrollView
    ///
    func configure(scrollView: UIScrollView) {
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Add padding at the end to account for overflow button
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Constants.stackButtonWidth)
    }


    /// Sets up the Constraints
    ///
    func configureConstraints() {
        let insets = Constants.scrollableStackViewInsets

        let overflowTrailingConstraint = overflowToggleItem.trailingAnchor.constraint(equalTo: trailingAnchor)
        overflowTrailingConstraint.priority = UILayoutPriorityDefaultLow

        NSLayoutConstraint.activate([
            overflowToggleItem.topAnchor.constraint(equalTo: topAnchor),
            overflowToggleItem.bottomAnchor.constraint(equalTo: bottomAnchor),
            overflowToggleItem.leadingAnchor.constraint(greaterThanOrEqualTo: scrollableStackView.trailingAnchor),
            overflowTrailingConstraint
        ])

        NSLayoutConstraint.activate([
            topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDivider.topAnchor.constraint(equalTo: topAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: Constants.topDividerHeight)
        ])

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1 * insets.right),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            scrollableStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollableStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollableStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollableStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollableStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            ])
    }


    /// Disables scrolling whenever there's no actual overflow
    ///
    func refreshScrollingLock() {
        layoutIfNeeded()

        scrollView.isScrollEnabled = scrollView.contentSize.width > scrollView.frame.width
    }
}



// MARK: - Animation Helpers
//
private extension FormatBar {

    private var scrollableContentSize: CGSize {
        return scrollView.contentSize
    }

    private var scrollableVisibleSize: CGSize {
        return scrollView.frame.size
    }

    func animate(item: FormatBarItem, visible: Bool, withDelay delay: TimeInterval) {
        let hide = {
            item.transform = Animations.itemPop.initialTransform
            item.alpha = 0
        }

        let unhide = {
            item.transform = CGAffineTransform.identity
            item.alpha = 1.0
        }

        if visible {
            hide()
        } else {
            unhide()
        }

        UIView.animate(withDuration: Animations.itemPop.duration,
                       delay: delay,
                       usingSpringWithDamping: Animations.itemPop.springDamping,
                       initialSpringVelocity: Animations.itemPop.springInitialVelocity,
                       options: [],
                       animations: (visible) ? unhide : hide,
                       completion: nil)
    }

    enum OverflowToggleAnimationDirection {
        case horizontal
        case vertical

        var transform: CGAffineTransform {
            switch self {
            case .horizontal:
                return .identity
            case .vertical:
                return CGAffineTransform(rotationAngle: (.pi / 2))
            }
        }
    }

    func rotateOverflowToggleItem(_ direction: OverflowToggleAnimationDirection, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let transform = {
            self.overflowToggleItem.transform = direction.transform
        }

        if (animated) {
            UIView.animate(withDuration: Animations.toggleItem.duration,
                           delay: 0,
                           usingSpringWithDamping: Animations.toggleItem.springDamping,
                           initialSpringVelocity: Animations.toggleItem.springInitialVelocity,
                           options: [],
                           animations: transform,
                           completion: completion)
        } else {
            transform()
            completion?(true)
        }
    }
}


// MARK: - Private Constants
//
private extension FormatBar {

    struct Animations {
        static let durationLong = TimeInterval(0.3)
        static let durationShort = TimeInterval(0.15)
        static let delayZero = TimeInterval(0)
        static let peekWidthRatio = CGFloat(0.05)

        struct toggleItem {
            static let duration = TimeInterval(0.6)
            static let springDamping = CGFloat(0.5)
            static let springInitialVelocity = CGFloat(0.1)
        }

        struct itemPop {
            static let interItemAnimationDelay = TimeInterval(0.1)
            static let initialTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            static let duration = TimeInterval(0.65)
            static let springDamping = CGFloat(0.4)
            static let springInitialVelocity = CGFloat(1.0)
        }
    }

    struct Constants {
        static let fixedSeparatorMidPointPaddingX = CGFloat(5)
        static let fixedStackViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let scrollableStackViewInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        static let stackViewCompactSpacing = CGFloat(0)
        static let stackViewRegularSpacing = CGFloat(0)
        static let stackButtonWidth = CGFloat(44)
        static let topDividerHeight = CGFloat(1)
    }
}
