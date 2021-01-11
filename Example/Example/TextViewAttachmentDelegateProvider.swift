import Foundation
import Aztec
import UIKit
import AVFoundation
import AVKit

class TextViewAttachmentDelegateProvider: NSObject, TextViewAttachmentDelegate {

    fileprivate var currentSelectedAttachment: MediaAttachment?
    let baseController: UIViewController
    let attachmentTextAttributes: [NSAttributedString.Key: Any]

    init(baseController: UIViewController, attachmentTextAttributes: [NSAttributedString.Key: Any]) {
        self.baseController = baseController
        self.attachmentTextAttributes = attachmentTextAttributes
    }

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {

        switch attachment {
        case let videoAttachment as VideoAttachment:
            guard let posterURL = videoAttachment.posterURL else {
                // Let's get a frame from the video directly
                if let videoURL = videoAttachment.mediaURL {
                    exportPreviewImageForVideo(atURL: videoURL, onCompletion: success, onError: failure)
                } else {
                    exportPreviewImageForVideo(atURL: url, onCompletion: success, onError: failure)
                }
                return
            }
            downloadImage(from: posterURL, success: success, onFailure: failure)
        case let imageAttachment as ImageAttachment:
            if let imageURL = imageAttachment.url {
                downloadImage(from: imageURL, success: success, onFailure: failure)
            }
        default:
            failure()
        }
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return placeholderImage(for: attachment)
    }

    func placeholderImage(for attachment: NSTextAttachment) -> UIImage {        
        var placeholderImage: UIImage
        switch attachment {
        case _ as ImageAttachment:
            placeholderImage = UIImage.systemImage("photo")
        case _ as VideoAttachment:
            placeholderImage = UIImage.systemImage("video")
        default:
            placeholderImage = UIImage.systemImage("paperclip")
        }
        if #available(iOS 13.0, *) {
            placeholderImage = placeholderImage.withTintColor(.label)
        }
        return placeholderImage
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        guard let image = imageAttachment.image else {
            return nil
        }

        return image.saveToTemporaryFile()
    }

    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
        print("Attachment \(attachment.identifier) removed.\n")
    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
        switch attachment {
        case let attachment as HTMLAttachment:
            displayUnknownHtmlEditor(for: attachment, in: textView)
        case let attachment as MediaAttachment:
            selected(in: textView, textAttachment: attachment, atPosition: position)
        default:
            break
        }
    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
        deselected(in: textView, textAttachment: attachment, atPosition: position)
    }

    fileprivate func resetMediaAttachmentOverlay(_ mediaAttachment: MediaAttachment) {
        mediaAttachment.overlayImage = nil
        mediaAttachment.message = nil
    }

    func selected(in textView: TextView, textAttachment attachment: MediaAttachment, atPosition position: CGPoint) {
        if (currentSelectedAttachment == attachment) {
            displayActions(in: textView, forAttachment: attachment, position: position)
        } else {
            if let selectedAttachment = currentSelectedAttachment {
                resetMediaAttachmentOverlay(selectedAttachment)
                textView.refresh(selectedAttachment)
            }

            // and mark the newly tapped attachment
            if attachment.message == nil {
                let message = NSLocalizedString("Options", comment: "Options to show when tapping on a media object on the post/page editor.")
                attachment.message = NSAttributedString(string: message, attributes: attachmentTextAttributes)
            }
            attachment.overlayImage = UIImage.init(systemName: "square.and.pencil")!.withRenderingMode(.alwaysTemplate)
            textView.refresh(attachment)
            currentSelectedAttachment = attachment
        }
    }

    func deselected(in textView: TextView,textAttachment attachment: NSTextAttachment, atPosition position: CGPoint) {
        currentSelectedAttachment = nil
        if let mediaAttachment = attachment as? MediaAttachment {
            resetMediaAttachmentOverlay(mediaAttachment)
            textView.refresh(mediaAttachment)
        }
    }

    func displayVideoPlayer(for videoURL: URL) {
        let asset = AVURLAsset(url: videoURL)
        let controller = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        controller.showsPlaybackControls = true
        controller.player = player
        player.play()
        baseController.present(controller, animated:true, completion: nil)
    }
}

// MARK: - Media fetch methods
//
private extension TextViewAttachmentDelegateProvider {

    func exportPreviewImageForVideo(atURL url: URL, onCompletion: @escaping (UIImage) -> (), onError: @escaping () -> ()) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVURLAsset(url: url)
            guard asset.isExportable else {
                onError()
                return
            }
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: CMTimeMake(value: 2, timescale: 1))],
                                                     completionHandler: { (time, cgImage, actualTime, result, error) in
                                                        guard let cgImage = cgImage else {
                                                            DispatchQueue.main.async {
                                                                onError()
                                                            }
                                                            return
                                                        }
                                                        let image = UIImage(cgImage: cgImage)
                                                        DispatchQueue.main.async {
                                                            onCompletion(image)
                                                        }
            })
        }
    }

    func downloadImage(from url: URL, success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            DispatchQueue.main.async {
                guard self != nil else {
                    return
                }

                guard error == nil, let data = data, let image = UIImage(data: data, scale: UIScreen.main.scale) else {
                    failure()
                    return
                }

                success(image)
            }
        }

        task.resume()
    }
}

// MARK: - Media attachments actions
//
extension TextViewAttachmentDelegateProvider {
    
    func displayActions(in textView: TextView, forAttachment attachment: MediaAttachment, position: CGPoint) {
        let mediaID = attachment.identifier
        let title: String = NSLocalizedString("Media Options", comment: "Title for action sheet with media options.")
        let message: String? = nil
        let alertController = UIAlertController(title: title, message:message, preferredStyle: .actionSheet)
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "User action to dismiss media options."),
                                          style: .cancel,
                                          handler: { [weak self] (action) in
                                            self?.resetMediaAttachmentOverlay(attachment)
                                            textView.refresh(attachment)
        }
        )
        alertController.addAction(dismissAction)

        let removeAction = UIAlertAction(title: NSLocalizedString("Remove Media", comment: "User action to remove media."),
                                         style: .destructive,
                                         handler: { (action) in
                                            textView.remove(attachmentID: mediaID)
        })
        alertController.addAction(removeAction)

        if let imageAttachment = attachment as? ImageAttachment {
            let detailsAction = UIAlertAction(title:NSLocalizedString("Media Details", comment: "User action to change media details."),
                                              style: .default,
                                              handler: { [weak self] (action) in
                                                self?.displayDetailsForAttachment(in: textView, imageAttachment, position: position)
            })
            alertController.addAction(detailsAction)
        } else if let videoAttachment = attachment as? VideoAttachment, let videoURL = videoAttachment.mediaURL {
            let detailsAction = UIAlertAction(title:NSLocalizedString("Play Video", comment: "User action to play video."),
                                              style: .default,
                                              handler: { [weak self] (action) in
                                                self?.displayVideoPlayer(for: videoURL)
            })
            alertController.addAction(detailsAction)
        }

        alertController.title = title
        alertController.message = message
        alertController.popoverPresentationController?.sourceView = textView
        alertController.popoverPresentationController?.sourceRect = CGRect(origin: position, size: CGSize(width: 1, height: 1))
        alertController.popoverPresentationController?.permittedArrowDirections = .any
        baseController.present(alertController, animated:true, completion: nil)
    }

    func displayDetailsForAttachment(in textView: TextView, _ attachment: ImageAttachment, position:CGPoint) {

        let caption = textView.caption(for: attachment)
        let detailsViewController = AttachmentDetailsViewController.controller(for: attachment, with: caption)

        let linkInfo = textView.linkInfo(for: attachment)
        let linkRange = linkInfo?.range
        let linkUpdateRange = linkRange ?? textView.textStorage.ranges(forAttachment: attachment).first!

        if let linkURL = linkInfo?.url {
            detailsViewController.linkURL = linkURL
        }

        detailsViewController.onUpdate = { (alignment, size, srcURL, linkURL, alt, caption) in

            let attachment = textView.edit(attachment) { attachment in
                if let alt = alt {
                    attachment.extraAttributes["alt"] = .string(alt)
                }

                attachment.alignment = alignment
                attachment.size = size
                attachment.updateURL(srcURL)
            }

            if let caption = caption, caption.length > 0 {
                textView.replaceCaption(for: attachment, with: caption)
            } else {
                textView.removeCaption(for: attachment)
            }

            if let newLinkURL = linkURL {
                textView.setLink(newLinkURL, inRange: linkUpdateRange)
            } else if linkURL != nil {
                textView.removeLink(inRange: linkUpdateRange)
            }
        }

        let selectedRange = textView.selectedRange

        detailsViewController.onDismiss = {
            textView.becomeFirstResponder()
            textView.selectedRange = selectedRange
        }

        let navigationController = UINavigationController(rootViewController: detailsViewController)
        baseController.present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - Unknown HTML
//
private extension TextViewAttachmentDelegateProvider {

    func displayUnknownHtmlEditor(for attachment: HTMLAttachment, in textView: TextView) {
        let targetVC = UnknownEditorViewController(attachment: attachment)
        targetVC.onDidSave = { [weak self] html in
            textView.edit(attachment) { updated in
                updated.rawHTML = html
            }

            self?.baseController.dismiss(animated: true, completion: nil)
        }

        targetVC.onDidCancel = { [weak self] in
            self?.baseController.dismiss(animated: true, completion: nil)
        }

        let navigationController = UINavigationController(rootViewController: targetVC)
        displayAsPopover(viewController: navigationController)
    }

    func displayAsPopover(viewController: UIViewController) {        
        viewController.preferredContentSize = baseController.view.frame.size

        let presentationController = viewController.popoverPresentationController
        presentationController?.sourceView = baseController.view
        presentationController?.delegate = self

        baseController.present(viewController, animated: true, completion: nil)
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
//
extension TextViewAttachmentDelegateProvider: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    }
}
