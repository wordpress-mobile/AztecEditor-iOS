import Foundation
import UIKit


// MARK: - FormatBar
//
open class FormatBar: UIView {

    /// Format Bar's Delegate
    ///
    open weak var formatter: FormatBarDelegate?


    open var items = [FormatBarItem]() {
        willSet {
            for item in items {
                item.removeFromSuperview()
            }
        }
        didSet {
            for item in items {
                configureButtonStyle(item)
                configureButtonAction(item)
            }
        }
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



    // MARK: - Initializers



    func configureButtonStyle(_ button: FormatBarItem) {
        button.tintColor = tintColor
        button.selectedTintColor = selectedTintColor
        button.highlightedTintColor = highlightedTintColor
        button.disabledTintColor = disabledTintColor
    }


    func configureButtonAction(_ button: FormatBarItem) {
        button.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
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
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: fixedStackView.leadingAnchor, constant: -1 * Constants.fixedLeftPadding)
            ])

        NSLayoutConstraint.activate([
            fixedStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1 * Constants.edgesSpacing),
            fixedStackView.topAnchor.constraint(equalTo: topAnchor),
            fixedStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

        NSLayoutConstraint.activate([
            scrollableStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Constants.edgesSpacing),
            scrollableStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -1 * Constants.edgesSpacing),
            scrollableStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollableStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollableStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            scrollableStackView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor, constant: -2 *  Constants.edgesSpacing)
            ])
    }
}


// MARK: - Private Constants
//
private extension FormatBar {

    struct Constants {
        static let edgesSpacing = CGFloat(10)
        static let fixedLeftPadding = CGFloat(10)
        static let stackViewSpacing = CGFloat(7)
    }
}
