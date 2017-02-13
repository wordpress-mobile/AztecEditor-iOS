import Foundation
import UIKit


open class FormatBar: UIToolbar
{

    open weak var formatter: FormatBarDelegate?


    override open var items: [UIBarButtonItem]? {
        didSet {
            for item in formatBarItems {
                configureButtonStyle(item)
                configureButtonAction(item)
            }
        }
    }


    override open var tintColor: UIColor? {
        didSet {
            for item in formatBarItems {
                item.tintColor = tintColor
            }
        }
    }


    open var selectedTintColor: UIColor? {
        didSet {
            for item in formatBarItems {
                item.selectedTintColor = selectedTintColor
            }
        }
    }


    open var highlightedTintColor: UIColor? {
        didSet {
            for item in formatBarItems {
                item.highlightedTintColor = highlightedTintColor
            }
        }
    }


    open var disabledTintColor: UIColor? {
        didSet {
            for item in formatBarItems {
                item.disabledTintColor = disabledTintColor
            }
        }
    }


    open var enabled = true {
        didSet {
            for item in formatBarItems {
                item.isEnabled = enabled
            }
        }
    }


    open var formatBarItems: [FormatBarItem] {
        guard let items = items else {
            return [FormatBarItem]()
        }
        return items.filter({ (element) -> Bool in
            if let _ = element as? FormatBarItem {
                return true
            }
            return false
        }) as! [FormatBarItem]
    }


    // MARK: - Styles


    func configureButtonStyle(_ button: FormatBarItem) {
        button.tintColor = tintColor
        button.selectedTintColor = selectedTintColor
        button.highlightedTintColor = highlightedTintColor
        button.disabledTintColor = disabledTintColor
    }


    func configureButtonAction(_ button: FormatBarItem) {
        button.target = self
        button.action = #selector(type(of: self).handleButtonAction(_:))
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


    func handleButtonAction(_ sender: FormatBarItem) {
        formatter?.handleActionForIdentifier(sender.identifier!)
    }

}
