import UIKit


// MARK: - FormatBar
//
open class FormatBar: UIView {

    /// Format Bar's Delegate
    ///
    open weak var formatter: FormatBarDelegate?

    /// Called whenever a default or overflow bar item is tapped
    ///
    open var barItemHandler: ((FormatBarItem) -> Void)? = nil

    /// Called whenever the leading item (if present) is tapped
    ///
    open var leadingItemHandler: ((UIButton) -> Void)? = nil

    /// Called whenever the trailing item (if present) is tapped
    ///
    open var trailingItemHandler: ((UIButton) -> Void)? = nil

    /// Container ScrollView
    ///
    fileprivate let scrollView = UIScrollView()


    /// StackView embedded within the ScrollView
    ///
    fileprivate let scrollableStackView = UIStackView()


    /// Top and bottom dividing lines
    ///
    fileprivate let topDivider = UIView()
    fileprivate let bottomDivider = UIView()

    /// A leading item that will displayed in front of any default items.
    /// A divider will be drawn between the leading item and any default items.
    /// If set to a FormatBarItem, the appearance will match the default items in the bar.
    ///
    public var leadingItem: UIButton? = nil {
        didSet {
            /// If there was already a leading item in the bar, remove it
            if let existingItem = oldValue,
                let firstView = scrollableStackView.arrangedSubviews.first,
                existingItem == firstView {
                firstView.removeFromSuperview()
            }

            if let item = leadingItem {
                if let formatBarItem = item as? FormatBarItem {
                    configureStylesFor(formatBarItem)
                }

                item.addTarget(self, action: #selector(handleLeadingButtonAction), for: .touchUpInside)
                item.addTarget(self, action: #selector(handleButtonTouch), for: .touchDown)

                populateLeadingItem()
            }
        }
    }

    /// A trailing item that will displayed after any default items.
    /// No divider will be drawn before the trailing item.
    /// If set to a FormatBarItem, the appearance will match the default items in the bar.
    /// If a custom trailing item is set, no overflow toggle will be shown.
    ///
    public var trailingItem: UIButton? = nil {
        didSet {
            updateScrollViewInsets()

            trailingItemContainer.arrangedSubviews.forEach({ $0.removeFromSuperview() })

            if let item = trailingItem {
                if let formatBarItem = item as? FormatBarItem {
                    configureStylesFor(formatBarItem)
                }

                item.addTarget(self, action: #selector(handleTrailingButtonAction), for: .touchUpInside)
                item.addTarget(self, action: #selector(handleButtonTouch), for: .touchDown)

                trailingItemContainer.addArrangedSubview(item)

                setOverflowItemsVisible(false)
            }

            updateOverflowToggleItemVisibility()
        }
    }
    fileprivate var trailingItemContainer = UIStackView()


    /// FormatBarItems to be displayed when the bar is in its default collapsed state.
    /// Set using `setDefaultItems(_:overflowItems:)`.
    ///
    fileprivate(set) var defaultItems = [FormatBarItem]()


    /// Extra FormatBarItems to be displayed when the bar is in its expanded state.
    /// Set using `setDefaultItems(_:overflowItems:)`.
    ///
    fileprivate(set) var overflowItems = [FormatBarItem]()


    /// FormatBarItem used to toggle the bar's expanded state
    ///
    fileprivate lazy var overflowToggleItem: FormatBarItem = {
        let item = FormatBarItem(image: UIImage(), identifier: nil)
        self.configureStylesFor(item)

        item.addTarget(self, action: #selector(handleToggleButtonAction), for: .touchUpInside)
        item.addTarget(self, action: #selector(handleButtonTouch), for: .touchDown)

        return item
    }()


    /// The icon to show on the overflow toggle button
    ///
    public var overflowToggleIcon: UIImage? {
        set {
            overflowToggleItem.setImage(newValue, for: .normal)
        }
        get {
            return overflowToggleItem.image(for: .normal)
        }
    }


    /// Returns the collection of all of the FormatBarItems
    ///
    public var items: [FormatBarItem] {
        return scrollableStackView.arrangedSubviews.filter({ $0 is FormatBarItem }) as! [FormatBarItem]
    }

    /// Returns the collection of all items in the stackview that are currently hidden
    ///
    private var hiddenItems: [FormatBarItem] {
        return scrollableStackView.arrangedSubviews.filter({ $0.isHiddenInStackView && $0 is FormatBarItem }) as! [FormatBarItem]
    }

    /// Returns all of the dividers (including the top divider) in the bar
    ///
    private var dividers: [UIView] {
        return scrollableStackView.arrangedSubviews.filter({ !($0 is FormatBarItem) }) + [topDivider]
    }

    /// Returns a list of all default items that don't fit within the current
    /// screen width. They will be hidden, and then displayed when overflow
    /// items are revealed.
    ///
    private var overflowedDefaultItems: ArraySlice<FormatBarItem> {
        // Work out how many items we can show in the bar
        let availableWidth = visibleWidth
        guard availableWidth > 0 else { return [] }

        let visibleItemCount = Int(floor(availableWidth / Constants.defaultButtonWidth))

        let allItems = items
        let leadingItemCount = leadingItem != nil ? 1 : 0
        guard visibleItemCount < (defaultItems.compactMap({ $0 }).count + leadingItemCount) else { return [] }

        return allItems.suffix(from: visibleItemCount)
    }


    /// Returns the current width currently available to fit toolbar items without scrolling.
    ///
    private var visibleWidth: CGFloat {
        return frame.width - scrollView.contentInset.left - scrollView.contentInset.right
    }

    fileprivate var trailingInset: CGFloat {
        if let trailingItem = trailingItem {
            trailingItem.sizeToFit()
            return trailingItem.bounds.size.width + Constants.trailingButtonMargin
        } else {
            return Constants.defaultButtonWidth
        }
    }

    /// Returns true if any of the overflow items in the bar are currently hidden
    ///
    private var overflowItemsHidden: Bool {
        if let _ = overflowItems.first(where: { $0.isHiddenInStackView }) {
            return true
        }

        return false
    }

    /// Tint Color
    ///
    override open var tintColor: UIColor? {
        didSet {
            for item in items + [overflowToggleItem] {
                item.normalTintColor = tintColor
            }
        }
    }


    /// Tint Color to be applied over Selected Items
    ///
    open var selectedTintColor: UIColor? {
        didSet {
            for item in items + [overflowToggleItem] {
                item.selectedTintColor = selectedTintColor
            }
        }
    }


    /// Tint Color to be applied over Highlighted Items
    ///
    open var highlightedTintColor: UIColor? {
        didSet {
            for item in items + [overflowToggleItem] {
                item.highlightedTintColor = highlightedTintColor
            }
        }
    }


    /// Tint Color to be applied over Disabled Items
    ///
    open var disabledTintColor: UIColor? {
        didSet {
            for item in items + [overflowToggleItem] {
                item.disabledTintColor = disabledTintColor
            }
        }
    }


    /// Tint Color to be applied to dividers
    ///
    open var dividerTintColor: UIColor? {
        didSet {
            for divider in (dividers + [topDivider, bottomDivider]) {
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

            overflowToggleItem.isEnabled = enabled
        }
    }

    open override var bounds: CGRect {
        didSet {
            updateVisibleItemsForCurrentBounds()
        }
    }
    open override var frame: CGRect {
        didSet {
            updateVisibleItemsForCurrentBounds()
        }
    }

    fileprivate func updateVisibleItemsForCurrentBounds() {
        guard overflowItemsHidden else { return }

        // Ensure that any items that wouldn't fit are hidden
        let allItems = items
        let overflowedItems = overflowedDefaultItems + overflowItems

        for item in allItems {
            item.isHiddenInStackView = overflowedItems.contains(item)
        }
    }

    /// The user interface direction for the FormatBar semantic content attribute.
    ///
    private var layoutDirection: UIUserInterfaceLayoutDirection {
        return UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute)
    }

    /// System-applied height constraint, used to resize the format bar as necessary.
    ///
    fileprivate var heightConstraint: NSLayoutConstraint? = nil

    /// Overflow toggle item leading constraint when using RTL layout or nil for LTR layout
    ///
    var overflowToggleItemRTLLeadingConstraint: NSLayoutConstraint?

    // MARK: - Initializers


    public init() {
        super.init(frame: .zero)
        backgroundColor = .white

        autoresizingMask = [ .flexibleHeight ]

        configure(scrollView: scrollView)
        configureScrollableStackView()

        addSubview(scrollView)
        scrollView.addSubview(scrollableStackView)

        topDivider.translatesAutoresizingMaskIntoConstraints = false
        bottomDivider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topDivider)
        addSubview(bottomDivider)

        overflowToggleItem.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overflowToggleItem)

        trailingItemContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trailingItemContainer)
        configureConstraints()
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()

        updateForSafeAreaInsets()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateOverflowToggleItemRTLConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }


    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateVisibleItemsForCurrentBounds()
    }

    @available(iOS 11.0, *)
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()

        updateForSafeAreaInsets()
    }

    // We're overriding this method so we can easily access the system height
    // constraint that is automatically created when the toolbar is initialized.
    // This allows us to resize the toolbar as required later.
    open override func addConstraint(_ constraint: NSLayoutConstraint) {
        if constraint.firstAttribute == .height {
            self.heightConstraint = constraint
        }

        super.addConstraint(constraint)
    }

    open override var intrinsicContentSize: CGSize {
        var height = Constants.defaultBarHeight
        if let heightConstraint = self.heightConstraint {
            height = heightConstraint.constant
        }

        return CGSize(width: bounds.width, height: height)
    }

    // MARK: - Styles

    /// Selects all of the FormatBarItems matching a collection of identifiers
    ///
    public func selectItemsMatchingIdentifiers(_ identifiers: [String]) {
        let identifiers = Set(identifiers)

        for item in items {
            if let alternativeIcons = item.alternativeIcons, alternativeIcons.count > 0 {
                // If the item has a matching alternative identifier, use that first and set selected
                if let alternativeIdentifier = alternativeIcons.keys.first(where: { identifiers.contains($0) }) {
                    item.useAlternativeIconForIdentifier(alternativeIdentifier)
                    item.isSelected = true
                } else {
                    // If the item has alternative identifiers, but none of them match,
                    // reset the icon and deselect it
                    item.resetIcon()
                    item.isSelected = false
                }
            } else if let identifier = item.identifier {
                // Otherwise, select it if the identifier matches
                item.isSelected = identifiers.contains(identifier)
            }
        }
    }


    // MARK: - Actions

    /// Configure the set of default and overflow items used in the format bar. If a set of overflow
    /// items is provided, an overflow toggle control will be displayed to allow a user to toggle
    /// their visibility.
    ///
    public func setDefaultItems(_ defaultItems: [FormatBarItem], overflowItems: [FormatBarItem] = []) {
        let newItems = defaultItems + overflowItems
        let oldItems = self.defaultItems + self.overflowItems

        configure(items: newItems)

        self.defaultItems = defaultItems
        self.overflowItems = overflowItems

        if newItems.count > 0 && oldItems.count > 0 {
            // Fade out all existing items and pop in new ones
            fadeItems(oldItems,
                      visible: false,
                      completion: {
                        self.populateItems()
                        self.popItems(newItems, visible: true, animated: true)
                        self.updateOverflowItemVisibility()
            })
        } else {
            self.populateItems()
            self.updateOverflowItemVisibility()
        }
    }

    fileprivate func updateOverflowItemVisibility() {
        updateVisibleItemsForCurrentBounds()

        let overflowVisible = UserDefaults.standard.bool(forKey: Constants.overflowExpandedUserDefaultsKey)
        setOverflowItemsVisible(overflowVisible && trailingItem == nil, animated: false)

        if overflowVisible {
            rotateOverflowToggleItem(.vertical, animated: false)
        }

        updateOverflowToggleItemVisibility()
    }

    fileprivate func updateOverflowToggleItemVisibility() {
        let hasOverflowItems = !overflowItems.isEmpty
        overflowToggleItem.isHidden = !hasOverflowItems || trailingItem != nil
    }

    /// Updates the overflowToggleItemRTLLeadingConstraint with the correct value. On LTR layout this function does nothing.
    ///
    private func updateOverflowToggleItemRTLConstraints() {
        overflowToggleItemRTLLeadingConstraint?.constant = scrollableStackView.frame.width - frame.width
    }

    @available(iOS 11.0, *)
    fileprivate func updateForSafeAreaInsets() {
        let newHeight = Constants.defaultBarHeight + safeAreaInsets.bottom
        if newHeight != heightConstraint?.constant {
            heightConstraint?.constant = newHeight
            updateDividerInsets()
            invalidateIntrinsicContentSize()

            // Fixes https://github.com/wordpress-mobile/WordPress-iOS/issues/8413.
            // Despite this method always being called on the main thread, without
            // this dispatch the toolbar's vertical position sometimes doesn't get
            // to be adjusted by the system to account for its height change.
            DispatchQueue.main.async {
                self.layoutIfNeeded()
            }
        }
    }

    @available(iOS 11.0, *)
    fileprivate func updateDividerInsets() {
        var dividerInsets = UIEdgeInsets.zero

        // If we have safe area insets, we'll end up expanding the toolbar vertically.
        // In that situation, we'll inset any dividers slightly to improve the appearance.
        if safeAreaInsets.bottom > 0 {
            dividerInsets = UIEdgeInsets(top: Constants.expandedFormatBarDividerInset,
                                         left: 0,
                                         bottom: Constants.expandedFormatBarDividerInset,
                                         right: 0)
        }

        scrollableStackView.arrangedSubviews.forEach({ item in
            if let item = item as? FormatBarDividerItem {
                item.layoutMargins = dividerInsets
            }
        })
    }

    @IBAction func handleButtonTouch(_ sender: FormatBarItem) {
        formatter?.formatBarTouchesBegan(self)
    }

    @IBAction func handleButtonAction(_ sender: FormatBarItem) {
        barItemHandler?(sender)
    }

    @IBAction func handleLeadingButtonAction(_ sender: FormatBarItem) {
        leadingItemHandler?(sender)
    }

    @IBAction func handleTrailingButtonAction(_ sender: FormatBarItem) {
        trailingItemHandler?(sender)
    }

    @IBAction func handleToggleButtonAction(_ sender: FormatBarItem) {
        let shouldExpand = overflowItemsHidden

        overflowToolbar(expand: shouldExpand)
    }

    /// Tell the toolbar to expand or collapse its overflow items.
    ///
    public func overflowToolbar(expand shouldExpand: Bool) {
        setOverflowItemsVisible(shouldExpand)

        let direction: OverflowToggleAnimationDirection = shouldExpand ? .vertical : .horizontal
        rotateOverflowToggleItem(direction, animated: true)

        UserDefaults.standard.set(shouldExpand, forKey: Constants.overflowExpandedUserDefaultsKey)

        formatter?.formatBar(self, didChangeOverflowState: (shouldExpand) ? .visible : .hidden)

        updateOverflowToggleItemRTLLayout(expand: shouldExpand, animated: true)
    }

    private func setOverflowItemsVisible(_ visible: Bool, animated: Bool = true) {
        guard overflowItemsHidden == visible else { return }

        // Animate backwards if we're disappearing
        let items = visible ? hiddenItems : (overflowedDefaultItems + overflowItems).reversed()

        popItems(items, visible: visible, animated: animated)
    }

    /// Updates the position of the overflow toggle item. This is necesary only for Right-to-Left layouts due to the special leading constraint.
    ///
    private func updateOverflowToggleItemRTLLayout(expand shouldExpand: Bool, animated: Bool) {
        guard layoutDirection == .rightToLeft else { return }

        overflowToggleItemRTLLeadingConstraint?.isActive = shouldExpand
        updateOverflowToggleItemRTLConstraints()
        if animated {
            UIView.animate(withDuration: Animations.durationShort) {
                self.layoutIfNeeded()
            }
        }
    }

    private func popItems(_ items: [FormatBarItem], visible: Bool, animated: Bool = true) {
        if animated && visible {
            guard items.count > 0 else { return }

            // Scale the individual item duration so it always takes the same amount of time
            let itemCount = Double(items.count)
            let duration = Animations.itemPop.totalAppearanceDuration / itemCount
            let delay = Animations.itemPop.totalInterItemDelay / itemCount

            for (index, item) in items.enumerated() {
                animate(item: item, visible: visible, withDuration: duration, delay: Double(index) * delay)
            }
        } else {
            scrollView.contentOffset = .zero
            items.forEach({ $0.isHiddenInStackView = !visible })
        }
    }

    private func fadeItems(_ items: [FormatBarItem], visible: Bool, completion: (() -> Void)? = nil) {
        let alpha: CGFloat = visible ? 1 : 0
        UIView.animate(withDuration: Animations.durationShort, animations: {
            items.forEach({ $0.alpha = alpha })
        }, completion: { _ in
            completion?()
        })
    }
}


// MARK: - Configuration Helpers
//
private extension FormatBar {

    /// Populates the bar with the combined default and overflow items.
    /// Overflow items will be hidden by default.
    ///
    func populateItems() {
        scrollableStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        populateLeadingItem()

        scrollableStackView.addArrangedSubviews(defaultItems)
        scrollableStackView.addArrangedSubviews(overflowItems)

        updateVisibleItemsForCurrentBounds()
    }

    func populateLeadingItem() {
        if let leadingItem = leadingItem {
            let hasDivider = scrollableStackView.arrangedSubviews.first is FormatBarDividerItem
            if !hasDivider {
                let divider = FormatBarDividerItem()
                divider.backgroundColor = dividerTintColor
                scrollableStackView.insertArrangedSubview(divider, at: 0)
            }

            scrollableStackView.insertArrangedSubview(leadingItem, at: 0)
        }
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
    func configure(items: [UIButton]) {
        for item in items {
            configure(item: item)
        }
    }


    /// Sets up a given bar item
    ///
    func configure(item: UIButton) {
        if let formatBarItem = item as? FormatBarItem {
            configureStylesFor(formatBarItem)
        }

        item.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
        item.addTarget(self, action: #selector(handleButtonTouch), for: .touchDown)
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
        scrollableStackView.flipIfNeeded(for: layoutDirection)
    }


    /// Sets up the ScrollView
    ///
    func configure(scrollView: UIScrollView) {
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.flipIfNeeded(for: layoutDirection)
        updateScrollViewInsets()
    }

    func updateScrollViewInsets() {
        // Add padding at the end to account for overflow button
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: trailingInset)
    }

    /// Sets up the Constraints
    ///
    func configureConstraints() {
        let leadingAnchor = safeAreaLayoutGuide.leadingAnchor
        let trailingAnchor = safeAreaLayoutGuide.trailingAnchor

        ///Overflow toggle item

        let overflowTrailingConstraint = overflowToggleItem.trailingAnchor.constraint(equalTo: trailingAnchor)
        overflowTrailingConstraint.priority = .defaultLow

        //Create the correct `overflowLeadingConstraint` for the current layout direction.
        let overflowLeadingConstraint: NSLayoutConstraint
        switch layoutDirection {
        case .leftToRight:
            overflowLeadingConstraint = overflowToggleItem.leadingAnchor.constraint(greaterThanOrEqualTo: scrollableStackView.trailingAnchor)
        case .rightToLeft:
            overflowLeadingConstraint = NSLayoutConstraint(
                item: overflowToggleItem,
                attribute: .leading,
                relatedBy: .greaterThanOrEqual,
                toItem: scrollableStackView,
                attribute: .trailing,
                multiplier: -1,
                constant: 0
            )
            self.overflowToggleItemRTLLeadingConstraint = overflowLeadingConstraint
        @unknown default:
            overflowLeadingConstraint = overflowToggleItem.leadingAnchor.constraint(greaterThanOrEqualTo: scrollableStackView.trailingAnchor)
        }

        ///Trailing item

        let trailingItemTrailingConstraint = trailingItemContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.trailingButtonMargin)
        trailingItemTrailingConstraint.priority = .defaultLow

        //Create the correct `trailingItemLeadingConstraint` for the current layout direction.
        let trailingItemLeadingConstraint: NSLayoutConstraint
        switch layoutDirection {
        case .leftToRight:
            trailingItemLeadingConstraint = trailingItemContainer.leadingAnchor.constraint(greaterThanOrEqualTo: scrollableStackView.trailingAnchor)
        case .rightToLeft:
            trailingItemLeadingConstraint = trailingItemContainer.leadingAnchor.constraint(greaterThanOrEqualTo: scrollableStackView.leadingAnchor)
        @unknown default:
            trailingItemLeadingConstraint = trailingItemContainer.leadingAnchor.constraint(greaterThanOrEqualTo: scrollableStackView.trailingAnchor)
        }

        NSLayoutConstraint.activate([
            overflowToggleItem.topAnchor.constraint(equalTo: topAnchor),
            overflowToggleItem.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            overflowLeadingConstraint,
            overflowTrailingConstraint
        ])

        NSLayoutConstraint.activate([
            trailingItemContainer.topAnchor.constraint(equalTo: topAnchor),
            trailingItemContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            trailingItemLeadingConstraint,
            trailingItemTrailingConstraint
        ])

        NSLayoutConstraint.activate([
            topDivider.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            topDivider.topAnchor.constraint(equalTo: topAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: Constants.horizontalDividerHeight)
        ])

        NSLayoutConstraint.activate([
            bottomDivider.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bottomDivider.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bottomDivider.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            bottomDivider.heightAnchor.constraint(equalToConstant: Constants.horizontalDividerHeight)
        ])

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: Constants.defaultBarHeight)
        ])

        NSLayoutConstraint.activate([
            scrollableStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollableStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollableStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollableStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollableStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])
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

    func animate(item: FormatBarItem, visible: Bool, withDuration duration: TimeInterval, delay: TimeInterval) {
        let hide = {
            item.transform = Animations.itemPop.initialTransform
            item.alpha = 0
        }

        let unhide = {
            item.transform = CGAffineTransform.identity
            item.alpha = 1.0
        }

        let pop = {
            UIView.animate(withDuration: Animations.itemPop.duration,
                           delay: delay,
                           usingSpringWithDamping: Animations.itemPop.springDamping,
                           initialSpringVelocity: Animations.itemPop.springInitialVelocity,
                           options: [],
                           animations: (visible) ? unhide : hide,
                           completion: nil)
        }

        if visible {
            hide()
            UIView.animate(withDuration: duration,
                           animations: { item.isHiddenInStackView = false },
                           completion: { _ in
                            pop()
            })
        } else {
            unhide()
            pop()
        }
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

// MARK: - UIScrollViewDelegate

extension FormatBar: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        formatter?.formatBarTouchesBegan(self)
    }
}

// MARK: - Constants
extension FormatBar {
    struct Constants {
        static let defaultBarHeight = CGFloat(44)
        static let defaultButtonWidth = Constants.defaultBarHeight
        static let defaultButtonHeight = Constants.defaultBarHeight
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
            static let initialTransform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            static let duration = TimeInterval(0.6)
            static let totalAppearanceDuration = TimeInterval(0.7)
            static let totalInterItemDelay = TimeInterval(0.2)
            static let springDamping = CGFloat(0.4)
            static let springInitialVelocity = CGFloat(1.0)
        }
    }
}

private extension FormatBar.Constants {
    static let overflowExpandedUserDefaultsKey = "AztecFormatBarOverflowExpandedKey"
    static let fixedSeparatorMidPointPaddingX = CGFloat(5)
    static let stackViewCompactSpacing = CGFloat(0)
    static let stackViewRegularSpacing = CGFloat(0)
    static let horizontalDividerHeight = CGFloat(1)
    static let trailingButtonMargin = CGFloat(12)
    static let expandedFormatBarDividerInset = CGFloat(5)
}

private extension UIView {
    /// Required to work around a bug in UIStackView where items don't become
    /// hidden / unhidden correctly if you set their `isHidden` property
    /// to the same value twice in a row. See http://www.openradar.me/22819594
    ///
    var isHiddenInStackView: Bool {
        set {
            if isHidden != newValue {
                isHidden = newValue
            }
        }

        get {
            return isHidden
        }
    }

    /// Flips the receiver horizontally if the given layout direction is .rightToLeft
    /// It is necesary for ScrollViews and its content to have a right-to-left scroll behavior
    ///
    /// - Parameter layoutDirection: The current user interface layout direction
    func flipIfNeeded(for layoutDirection: UIUserInterfaceLayoutDirection) {
        if layoutDirection == .rightToLeft {
            transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }
}
