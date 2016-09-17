import Foundation
import Aztec
import UIKit

class AttachmentDetailsViewController: UIViewController
{
    @IBOutlet var alignmentSegmentedControl: UISegmentedControl!
    @IBOutlet var sizeSegmentedControl: UISegmentedControl!
    var attachment: AztecTextAttachment?
    var onUpdate: (() -> Void)?


    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Properties", comment: "Attachment Properties Title")
        edgesForExtendedLayout = .None

        navigationController?.navigationBar.translucent = false

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                                            target: self,
                                                            action: #selector(cancelWasPressed))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done,
                                                            target: self,
                                                            action: #selector(doneWasPressed))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        guard let attachment = attachment else {
            fatalError()
        }

        let alignment = Alignment(attachmentAlignment: attachment.alignment)
        let size = Size(attachmentSize: attachment.size)

        alignmentSegmentedControl.selectedSegmentIndex = alignment.rawValue
        sizeSegmentedControl.selectedSegmentIndex = size.rawValue

    }

    @IBAction func cancelWasPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func doneWasPressed() {
        guard let alignment = Alignment(rawValue: alignmentSegmentedControl.selectedSegmentIndex),
            let size = Size(rawValue: sizeSegmentedControl.selectedSegmentIndex),
            attachment = attachment else
        {
            fatalError()
        }

        attachment.alignment = alignment.toAttachmentAlignment()
        attachment.size = size.toAttachmentSize()
        onUpdate?()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}


/// Private Helpers
///
private extension AttachmentDetailsViewController
{
    /// Aliases
    ///
    typealias AttachmentAlignment = AztecTextAttachment.Alignment
    typealias AttachmentSize = AztecTextAttachment.Size


    /// Maps an AztecTextAttachment.Alignment into a Integer based Enum, to aid in the mapping between
    /// the Attachment's data and the Segmented Control.
    ///
    enum Alignment: Int {
        case None
        case Left
        case Center
        case Right

        init(attachmentAlignment: AttachmentAlignment) {
            switch attachmentAlignment {
            case .None:     self = .None
            case .Left:     self = .Left
            case .Center:   self = .Center
            case .Right:    self = .Right
            }
        }

        func toAttachmentAlignment() -> AttachmentAlignment {
            switch self {
            case .None:     return .None
            case .Left:     return .Left
            case .Center:   return .Center
            case .Right:    return .Right
            }
        }
    }


    /// Maps an AztecTextAttachment.Size into a Integer based Enum, to aid in the mapping between
    /// the Attachment's data and the Segmented Control.
    ///
    enum Size: Int {
        case Thumbnail
        case Medium
        case Large
        case Maximum

        init(attachmentSize: AttachmentSize) {
            switch attachmentSize {
            case .Thumbnail:    self = .Thumbnail
            case .Medium:       self = .Medium
            case .Large:        self = .Large
            case .Maximum:      self = .Maximum
            }
        }

        func toAttachmentSize() -> AttachmentSize {
            switch self {
            case .Thumbnail:    return .Thumbnail
            case .Medium:       return .Medium
            case .Large:        return .Large
            case .Maximum:      return .Maximum
            }
        }
    }
}
