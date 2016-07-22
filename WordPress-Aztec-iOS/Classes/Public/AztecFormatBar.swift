import Foundation
import UIKit


public class AztecFormatBar: UIToolbar
{

    public var formatter: AztecFormatBarDelegate?


    override public var items: [UIBarButtonItem]? {
        didSet {
            for item in formatBarItems {
                configureButtonStyle(item)
                configureButtonAction(item)
            }
        }
    }


    override public var tintColor: UIColor? {
        didSet {
            for item in formatBarItems {
                item.tintColor = tintColor
            }
        }
    }


    public var selectedTintColor: UIColor? {
        didSet {
            for item in formatBarItems {
                item.selectedTintColor = selectedTintColor
            }
        }
    }


    public var highlightedTintColor: UIColor? {
        didSet {
            for item in formatBarItems {
                item.highlightedTintColor = highlightedTintColor
            }
        }
    }


    public var disabledTintColor: UIColor? {
        didSet {
            for item in formatBarItems {
                item.disabledTintColor = disabledTintColor
            }
        }
    }


    public var enabled = true {
        didSet {
            for item in formatBarItems {
                item.enabled = enabled
            }
        }
    }


    public var formatBarItems: [AztecFormatBarItem] {
        guard let items = items else {
            return [AztecFormatBarItem]()
        }
        return items.filter({ (element) -> Bool in
            if let _ = element as? AztecFormatBarItem {
                return true
            }
            return false
        }) as! [AztecFormatBarItem]
    }


    // MARK: - Styles


    func configureButtonStyle(button: AztecFormatBarItem) {
        button.tintColor = tintColor
        button.selectedTintColor = selectedTintColor
        button.highlightedTintColor = highlightedTintColor
        button.disabledTintColor = disabledTintColor
    }


    func configureButtonAction(button: AztecFormatBarItem) {
        button.target = self
        button.action = #selector(self.dynamicType.handleButtonAction(_:))
    }


    ///
    ///
    public func selectItemsMatchingIdentifiers(identifiers: [String]) {
        for item in formatBarItems {
            if let identifier = item.identifier {
                item.selected = identifiers.contains(identifier)
            }
        }
    }


    // MARK: - Actions


    func handleButtonAction(sender: AztecFormatBarItem) {
        formatter?.handleActionForIdentifier(sender.identifier!)
    }

}
