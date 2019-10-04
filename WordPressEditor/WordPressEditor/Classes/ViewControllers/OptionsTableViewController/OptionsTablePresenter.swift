import Aztec
import Foundation
import UIKit

/// This class takes care of instantiating and presenting the options table VC.
///
public class OptionsTablePresenter: NSObject {
    
    public typealias OnSelectHandler = (_ selected: Int) -> Void
    
    private var optionsTableViewController: OptionsTableViewController?
    private unowned let presentingTextView: TextView
    private unowned let presentingViewController: UIViewController
    
    // MARK: - Initializers
    
    public init(presentingViewController: UIViewController, presentingTextView: TextView) {
        self.presentingTextView = presentingTextView
        self.presentingViewController = presentingViewController
    }
    
    // MARK: - Presentation
    
    public func present(
        _ optionsTableViewController: OptionsTableViewController,
        fromBarItem barItem: FormatBarItem,
        selectedRowIndex index: Int?,
        onSelect: OnSelectHandler?) {
        
        self.optionsTableViewController = optionsTableViewController

        optionsTableViewController.onSelect = { [weak self] selected in
            self?.dismiss() {
                onSelect?(selected)
            }
        }
        
        let selectRow = {
            if let index = index {
                optionsTableViewController.selectRow(at: index)
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad  {
            present(optionsTableViewController, asPopoverFromBarItem: barItem, completion: selectRow)
        } else {
            presentAsInputView(optionsTableViewController)
            selectRow()
        }
    }
    
    private func present(
        _ optionsViewController: OptionsTableViewController,
        asPopoverFromBarItem barItem: FormatBarItem,
        completion: (() -> Void)? = nil) {
        
        optionsViewController.modalPresentationStyle = .popover
        optionsViewController.popoverPresentationController?.permittedArrowDirections = [.down]
        optionsViewController.popoverPresentationController?.sourceView = barItem
        optionsViewController.popoverPresentationController?.sourceRect = barItem.bounds
        optionsViewController.popoverPresentationController?.backgroundColor = optionsViewController.cellBackgroundColor
        optionsViewController.popoverPresentationController?.delegate = self
        
        presentingViewController.present(optionsViewController, animated: true, completion: completion)
        
        self.optionsTableViewController = optionsViewController
    }
    
    private func presentAsInputView(_ optionsViewController: OptionsTableViewController) {
        
        let inputViewController = UIInputViewController(nibName: nil, bundle: nil)
        
        inputViewController.addChild(optionsViewController)
        inputViewController.view.addSubview(optionsViewController.view)
        
        let frame = calculateOptionsInputViewControllerFrame()
        inputViewController.view.frame = frame
        optionsViewController.view.frame = frame
        
        presentingTextView.inputViewController = inputViewController
        presentingTextView.reloadInputViews()
        
        self.optionsTableViewController = optionsViewController
    }
    
    // MARK: - Dismissal
    
    public func dismiss(completion: (() -> ())? = nil) {
        guard let optionsViewController = optionsTableViewController else {
            return
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad  {
            optionsViewController.dismiss(animated: true, completion: completion)
        } else {
            presentingTextView.inputViewController = nil
            presentingTextView.reloadInputViews()
            completion?()
        }
        
        self.optionsTableViewController = nil
    }
    
    // MARK: - Presentation Status
    
    public func isOnScreen() -> Bool {
        return optionsTableViewController != nil        
    }
    
    // MARK: - Dimensions Calculation
    
    private func calculateOptionsInputViewControllerFrame() -> CGRect {
        if UIDevice.current.orientation.isPortrait {
            return CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 260)
        } else {
            return CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        }
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
//
extension OptionsTablePresenter: UIPopoverPresentationControllerDelegate {
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        if optionsTableViewController != nil {
            optionsTableViewController = nil
        }
    }
}
