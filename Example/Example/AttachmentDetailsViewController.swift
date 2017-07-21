import Foundation
import Aztec
import UIKit

class AttachmentDetailsViewController: UITableViewController
{
    @IBOutlet var alignmentSegmentedControl: UISegmentedControl!
    @IBOutlet var sizeSegmentedControl: UISegmentedControl!
    @IBOutlet var sourceURLTextField: UITextField!

    var attachment: ImageAttachment?
    var onUpdate: ((ImageAttachment.Alignment, ImageAttachment.Size, URL) -> Void)?


    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Properties", comment: "Attachment Properties Title")
        edgesForExtendedLayout = UIRectEdge()

        navigationController?.navigationBar.isTranslucent = false

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                            target: self,
                                                            action: #selector(cancelWasPressed))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneWasPressed))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let attachment = attachment else {
            fatalError()
        }

        let alignment = Alignment(attachmentAlignment: attachment.alignment)
        let size = Size(attachmentSize: attachment.size)

        alignmentSegmentedControl.selectedSegmentIndex = alignment.rawValue
        sizeSegmentedControl.selectedSegmentIndex = size.rawValue

        sourceURLTextField.text = attachment.url?.absoluteString
    }

    @IBAction func cancelWasPressed() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func doneWasPressed() {
        guard
            let alignment = Alignment(rawValue: alignmentSegmentedControl.selectedSegmentIndex),
            let size = Size(rawValue: sizeSegmentedControl.selectedSegmentIndex)
            else {
            fatalError()
        }
        
        guard let onUpdate = onUpdate,
            let urlString = sourceURLTextField.text,
            let url = URL(string:urlString) else {
            
            dismiss(animated: true, completion: nil)
            return
        }

        onUpdate(alignment.toAttachmentAlignment(), size.toAttachmentSize(), url)
        dismiss(animated: true, completion: nil)
    }

    class func controller() -> AttachmentDetailsViewController {
        let storyboard = UIStoryboard(name: "AttachmentDetailsViewController", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "AttachmentDetailsViewController") as! AttachmentDetailsViewController
    }

}


/// Private Helpers
///
private extension AttachmentDetailsViewController
{
    /// Aliases
    ///
    typealias AttachmentAlignment = ImageAttachment.Alignment
    typealias AttachmentSize = ImageAttachment.Size


    /// Maps an TextAttachment.Alignment into a Integer based Enum, to aid in the mapping between
    /// the Attachment's data and the Segmented Control.
    ///
    enum Alignment: Int {
        case none
        case left
        case center
        case right

        init(attachmentAlignment: AttachmentAlignment) {
            switch attachmentAlignment {
            case .none:     self = .none
            case .left:     self = .left
            case .center:   self = .center
            case .right:    self = .right
            }
        }

        func toAttachmentAlignment() -> AttachmentAlignment {
            switch self {
            case .none:     return .none
            case .left:     return .left
            case .center:   return .center
            case .right:    return .right
            }
        }
    }


    /// Maps an TextAttachment.Size into a Integer based Enum, to aid in the mapping between
    /// the Attachment's data and the Segmented Control.
    ///
    enum Size: Int {
        case thumbnail
        case medium
        case large
        case maximum

        init(attachmentSize: AttachmentSize) {
            switch attachmentSize {
            case .thumbnail:    self = .thumbnail
            case .medium:       self = .medium
            case .large:        self = .large
            case .full:         self = .maximum
            }
        }

        func toAttachmentSize() -> AttachmentSize {
            switch self {
            case .thumbnail:    return .thumbnail
            case .medium:       return .medium
            case .large:        return .large
            case .maximum:      return .full
            }
        }
    }
}
