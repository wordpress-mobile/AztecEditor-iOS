import Foundation
import UIKit
import Aztec


// MARK: - UnknownEditorViewController
//
class UnknownEditorViewController: UIViewController {

    /// HTML Editor
    ///
    fileprivate(set) var editorView: UITextView!

    /// Raw HTML To Be Edited
    ///
    fileprivate let htmlAttachment: HTMLAttachment


    /// Default Initializer
    ///
    /// - Parameter rawHTML: HTML To Be Edited
    ///
    init(htmlAttachment: HTMLAttachment) {
        self.htmlAttachment = htmlAttachment
        super.init(nibName: nil, bundle: nil)
    }


    /// Overriden Initializers
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("You should use the `init(rawHTML:)` initializer!")
    }


    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupEditorView()
        setupMainView()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        editorView.becomeFirstResponder()
    }
}


// MARK: - Private Helpers
//
private extension UnknownEditorViewController {

    func setupNavigationBar() {
        title = NSLocalizedString("Unknwon HTML", comment: "Title for Unknown HTML Editor")

        let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel Action")
        let saveTitle = NSLocalizedString("Save", comment: "Save Action")

        let cancelButton = UIBarButtonItem(title: cancelTitle, style: .plain, target: self, action: #selector(cancelWasPressed))
        let saveButton = UIBarButtonItem(title: saveTitle, style: .plain, target: self, action: #selector(saveWasPressed))

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
    }

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
        editorView.text = htmlAttachment.prettyHTML()
    }

    func setupMainView() {
        view.addSubview(editorView)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            editorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            editorView.topAnchor.constraint(equalTo: view.topAnchor),
            editorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}


// MARK: - Actions
//
extension UnknownEditorViewController {

    @IBAction func cancelWasPressed() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func saveWasPressed() {
        
    }
}


// MARK: - Constants
//
extension UnknownEditorViewController {

    struct Constants {
        static let defaultContentFont   = UIFont.systemFont(ofSize: 14)
    }
}
