import Foundation
import Aztec
import UIKit

class AttachmentDetailsViewController: UITableViewController
{
    @IBOutlet var alignmentSegmentedControl: UISegmentedControl!
    @IBOutlet var sizeSegmentedControl: UISegmentedControl!
    @IBOutlet var sourceURLTextField: UITextField!

    var attachment: TextAttachment?
    var onUpdate: ((TextAttachment.Alignment, TextAttachment.Size, NSURL) -> Void)?


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

        sourceURLTextField.text = attachment.url?.absoluteString
    }

    @IBAction func cancelWasPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func doneWasPressed() {
        guard
            let alignment = Alignment(rawValue: alignmentSegmentedControl.selectedSegmentIndex),
            let size = Size(rawValue: sizeSegmentedControl.selectedSegmentIndex)
            else {
            fatalError()
        }
        var sourceURL = NSURL()
        if let urlString = sourceURLTextField.text,
           let url = NSURL(string:urlString) {
            sourceURL = url
        }

        onUpdate?(alignment.toAttachmentAlignment(), size.toAttachmentSize(), sourceURL)
        
        dismissViewControllerAnimated(true, completion: nil)
    }

    class func controller() -> AttachmentDetailsViewController {
        let storyboard = UIStoryboard(name: "AttachmentDetailsViewController", bundle: nil)
        return storyboard.instantiateViewControllerWithIdentifier("AttachmentDetailsViewController") as! AttachmentDetailsViewController
    }

}


/// Private Helpers
///
private extension AttachmentDetailsViewController
{
    /// Aliases
    ///
    typealias AttachmentAlignment = TextAttachment.Alignment
    typealias AttachmentSize = TextAttachment.Size


    /// Maps an TextAttachment.Alignment into a Integer based Enum, to aid in the mapping between
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


    /// Maps an TextAttachment.Size into a Integer based Enum, to aid in the mapping between
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
            case .Full:      self = .Maximum
            }
        }

        func toAttachmentSize() -> AttachmentSize {
            switch self {
            case .Thumbnail:    return .Thumbnail
            case .Medium:       return .Medium
            case .Large:        return .Large
            case .Maximum:      return .Full
            }
        }
    }
}
