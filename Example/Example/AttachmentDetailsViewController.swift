import Foundation
import Aztec
import UIKit

class AttachmentDetailsViewController: UITableViewController
{
    @IBOutlet var alignmentSegmentedControl: UISegmentedControl!
    @IBOutlet var sizeSegmentedControl: UISegmentedControl!
    @IBOutlet var sourceURLTextField: UITextField!
    @IBOutlet var linkURLTextField: UITextField!
    @IBOutlet var captionTextView: UITextView!
    @IBOutlet var altTextField: UITextField!

    var attachment: ImageAttachment?
    var caption: NSAttributedString?
    var linkURL: URL?
    var onUpdate: ((_ alignment: ImageAttachment.Alignment?, _ size: ImageAttachment.Size, _ imageURL: URL, _ linkURL: URL?, _ altText: String?, _ captionText: NSAttributedString?) -> Void)?
    var onDismiss: (() -> ())?


    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let caption = caption {
            captionTextView.attributedText = caption
        }
        
        captionTextView.delegate = self
        
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

        alignmentSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        if let alignmentValue = attachment.alignment {
            let alignment = Alignment(attachmentAlignment: alignmentValue)
            alignmentSegmentedControl.selectedSegmentIndex = alignment.rawValue
        }

        let size = Size(attachmentSize: attachment.size)
        sizeSegmentedControl.selectedSegmentIndex = size.rawValue

        sourceURLTextField.text = attachment.url?.absoluteString

        linkURLTextField.text = linkURL?.absoluteString

        captionTextView.attributedText = caption
        altTextField.text = attachment.extraAttributes["alt"]?.toString()
    }

    @IBAction func cancelWasPressed() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func doneWasPressed() {
        var alignment: ImageAttachment.Alignment?
        if alignmentSegmentedControl.selectedSegmentIndex != UISegmentedControl.noSegment {
            alignment = Alignment(rawValue: alignmentSegmentedControl.selectedSegmentIndex)?.toAttachmentAlignment()
        }
        guard
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
        let alt = altTextField.text
        let caption = captionTextView.attributedText
        let linkURL = URL(string: linkURLTextField.text ?? "")
        onUpdate(alignment, size.toAttachmentSize(), url, linkURL, alt, caption)
        dismiss(animated: true, completion: onDismiss)
    }

    class func controller(for attachment: ImageAttachment, with caption: NSAttributedString?) -> AttachmentDetailsViewController {
        let storyboard = UIStoryboard(name: "AttachmentDetailsViewController", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "AttachmentDetailsViewController") as! AttachmentDetailsViewController
        
        viewController.attachment = attachment
        viewController.caption = caption
        
        return viewController
    }
}

extension AttachmentDetailsViewController: UITextViewDelegate {
    
    /// Delegate override because we don't allow paragraph breaking characters in captions
    ///
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let containsBreakingCharacters = text.contains(where: { (character) -> Bool in
            guard let characterName = Character.Name(rawValue: character) else {
                return false
            }
            
            return Character.paragraphBreakingCharacters.contains(characterName)
        })
        
        return !containsBreakingCharacters
    }
}


/// Private Helpers
///
private extension AttachmentDetailsViewController {
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
        case none

        init(attachmentSize: AttachmentSize) {
            switch attachmentSize {
            case .thumbnail:    self = .thumbnail
            case .medium:       self = .medium
            case .large:        self = .large
            case .full:         self = .maximum
            case .none:         self = .none
            }
        }

        func toAttachmentSize() -> AttachmentSize {
            switch self {
            case .thumbnail:    return .thumbnail
            case .medium:       return .medium
            case .large:        return .large
            case .maximum:      return .full
            case .none:         return .none
            }
        }
    }
}
