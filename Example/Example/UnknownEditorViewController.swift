import Foundation
import UIKit
import Aztec


// MARK: - UnknownEditorViewController
//
class UnknownEditorViewController: UIViewController {

    ///
    ///
    fileprivate(set) var editorView: UITextView!

    ///
    ///
    fileprivate var leftLayoutConstraint: NSLayoutConstraint!

    ///
    ///
    fileprivate var rightLayoutConstraint: NSLayoutConstraint!

    ///
    ///
    fileprivate var topLayoutConstraint: NSLayoutConstraint!

    ///
    ///
    fileprivate var bottomLayoutConstraint: NSLayoutConstraint!


    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupEditorView()
        setupMainView()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningToNotifications()
    }
}


// MARK: - Private Helpers
//
extension UnknownEditorViewController {

    func setupEditorView() {
        let storage = HTMLStorage(defaultFont: Constants.defaultContentFont)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)

        editorView = UITextView(frame: .zero, textContainer: container)
        editorView.accessibilityLabel = NSLocalizedString("HTML Content", comment: "Post HTML content")
        editorView.accessibilityIdentifier = "HTMLContentView"
        editorView.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupMainView() {
        view.backgroundColor = Constants.backgroundColor
        view.addSubview(editorView)
    }

    func setupConstraints() {
        let insets = Constants.defaultEdgeInsets

        bottomLayoutConstraint = editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        topLayoutConstraint = editorView.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top)
        leftLayoutConstraint = editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left)
        rightLayoutConstraint = editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right)

        NSLayoutConstraint.activate([topLayoutConstraint, bottomLayoutConstraint, leftLayoutConstraint, rightLayoutConstraint])
    }
}


// MARK: - Keyboard Handling
//
extension UnknownEditorViewController {

    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
    }

    func keyboardWillShow(_ notification: Notification) {
        refreshBottomInsetIfNeeded(notification)
    }

    func keyboardWillHide(_ notification: Notification) {
        refreshBottomInsetIfNeeded(notification)
    }

    func refreshBottomInsetIfNeeded(_ notification: Notification) {
        guard let duration = animationDuration(from: notification),
            let curve = animationCurve(from: notification),
            let frame = keyboardFrame(from: notification),
            let inset = bottomInset(for: frame)
        else {
            return
        }

        guard inset != bottomLayoutConstraint.constant else {
            return
        }

        animateBottomInset(curve: curve, duration: duration, inset: inset)
    }

    private func bottomInset(for keyboardFrame: CGRect) -> CGFloat? {
        return keyboardFrame.minY - view.frame.maxY - Constants.defaultEdgeInsets.bottom
    }

    private func keyboardFrame(from notification: Notification) -> CGRect? {
        let userInfo = notification.userInfo as? [String: AnyObject]
        let keyboardFrame = userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue

        return keyboardFrame?.cgRectValue
    }

    private func animationDuration(from notification: Notification) -> TimeInterval? {
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval
        return duration
    }

    private func animationCurve(from notification: Notification) -> UIViewAnimationCurve? {
        guard let rawCurve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIViewAnimationCurve(rawValue: rawCurve)
        else {
            return nil
        }
        
        return curve
    }

    private func animateBottomInset(curve: UIViewAnimationCurve, duration: TimeInterval, inset: CGFloat) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationDuration(duration)

        bottomLayoutConstraint.constant = inset
        view.layoutIfNeeded()

        UIView.commitAnimations()
    }
}


// MARK: - Constants
//
extension UnknownEditorViewController {

    struct Constants {
        static let defaultContentFont   = UIFont.systemFont(ofSize: 14)
        static let defaultEdgeInsets    = UIEdgeInsetsMake(70, 15, 15, 15)
        static let backgroundColor      = UIColor(hue: 0x29/255.0, saturation: 0x28/255.0, brightness: 0x29/255.0, alpha: 0x90/255.0)
    }
}
