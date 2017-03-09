import Foundation
import UIKit


// MARK: - FormatBar
//
open class FormatBar: UIView {

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


    override open var tintColor: UIColor? {
        didSet {
            for item in items {
                item.tintColor = tintColor
            }
        }
    }


    open var selectedTintColor: UIColor? {
        didSet {
            for item in items {
                item.selectedTintColor = selectedTintColor
            }
        }
    }


    open var highlightedTintColor: UIColor? {
        didSet {
            for item in items {
                item.highlightedTintColor = highlightedTintColor
            }
        }
    }


    open var disabledTintColor: UIColor? {
        didSet {
            for item in items {
                item.disabledTintColor = disabledTintColor
            }
        }
    }


    open var enabled = true {
        didSet {
            for item in items {
                item.isEnabled = enabled
            }
        }
    }


    }


    // MARK: - Styles


    func configureButtonStyle(_ button: FormatBarItem) {
        button.tintColor = tintColor
        button.selectedTintColor = selectedTintColor
        button.highlightedTintColor = highlightedTintColor
        button.disabledTintColor = disabledTintColor
    }


    func configureButtonAction(_ button: FormatBarItem) {
        button.addTarget(self, action: #selector(handleButtonAction), for: .touchUpInside)
    }


    ///
    ///
    open func selectItemsMatchingIdentifiers(_ identifiers: [FormattingIdentifier]) {
        for item in formatBarItems {
            if let identifier = item.identifier {
                item.selected = identifiers.contains(identifier)
            }
        }
    }


    // MARK: - Actions


    @IBAction func handleButtonAction(_ sender: FormatBarItem) {
        formatter?.handleActionForIdentifier(sender.identifier!)
    }
}
