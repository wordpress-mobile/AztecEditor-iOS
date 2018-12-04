import Aztec
import Foundation
import UIKit

/// This class takes care of instantiating and presenting the options table VC.
///
public class OptionsTablePresenter: NSObject {
    
    private var optionsViewController: OptionsTableViewController!
    private unowned let presentingTextView: TextView
    private unowned let presentingViewController: UIViewController
    
    // MARK: - Initializers
    
    public init(presentingViewController: UIViewController, presentingTextView: TextView) {
        self.presentingTextView = presentingTextView
        self.presentingViewController = presentingViewController
    }
    
    // MARK: - Presentation
    
    public func present(
        with options: [OptionsTableViewOption],
        fromBarItem barItem: FormatBarItem,
        selectedRowIndex index: Int?,
        onSelect: OptionsTableViewController.OnSelectHandler?) {
        
        optionsViewController = OptionsTableViewController(options: options)
        optionsViewController.cellDeselectedTintColor = .gray
        optionsViewController.onSelect = { [weak self] selected in
            self?.dismiss() {
                onSelect?(selected)
            }
        }
        
        let selectRow = {
            if let index = index {
                self.optionsViewController.selectRow(at: index)
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad  {
            present(optionsViewController, asPopoverFromBarItem: barItem, completion: selectRow)
        } else {
            presentAsInputView(optionsViewController)
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
        optionsViewController.popoverPresentationController?.backgroundColor = .white
        optionsViewController.popoverPresentationController?.delegate = self
        
        presentingViewController.present(optionsViewController, animated: true, completion: completion)
        
        self.optionsViewController = optionsViewController
    }
    
    private func presentAsInputView(_ optionsViewController: OptionsTableViewController) {
        
        let inputViewController = UIInputViewController(nibName: nil, bundle: nil)
        
        inputViewController.addChildViewController(optionsViewController)
        inputViewController.view.addSubview(optionsViewController.view)
        
        let frame = calculateOptionsInputViewControllerFrame()
        inputViewController.view.frame = frame
        optionsViewController.view.frame = frame
        
        presentingTextView.inputViewController = inputViewController
        presentingTextView.reloadInputViews()
        
        self.optionsViewController = optionsViewController
    }
    
    // MARK: - Dismissal
    
    public func dismiss(completion: (() -> ())? = nil) {
        guard let optionsViewController = optionsViewController else {
            return
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad  {
            optionsViewController.dismiss(animated: true, completion: completion)
        } else {
            presentingTextView.inputViewController = nil
            presentingTextView.reloadInputViews()
            completion?()
        }
        
        self.optionsViewController = nil
    }
    
    // MARK: - Presentation Status
    
    public func isOnScreen() -> Bool {
        return optionsViewController != nil        
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
    
    private func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    private func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        if optionsViewController != nil {
            optionsViewController = nil
        }
    }
}
