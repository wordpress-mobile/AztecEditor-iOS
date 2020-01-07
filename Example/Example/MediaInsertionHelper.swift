import Foundation
import UIKit
import Aztec
import AVFoundation
import Gridicons

class MediaInsertionHelper
{
    fileprivate var mediaErrorMode = false

    struct MediaProgressKey {
        static let mediaID = ProgressUserInfoKey("mediaID")
        static let videoURL = ProgressUserInfoKey("videoURL")
    }
    
    let richTextView: TextView

    var mediaMessageAttributes: [NSAttributedString.Key: Any]

    init(textView: TextView, messageAttributes: [NSAttributedString.Key: Any]) {
        self.richTextView = textView
        self.mediaMessageAttributes = messageAttributes
    }

    func saveToDisk(image: UIImage) -> URL {
        let fileName = "\(ProcessInfo.processInfo.globallyUniqueString)_file.jpg"

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            fatalError("Could not conert image to JPEG.")
        }

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        guard (try? data.write(to: fileURL, options: [.atomic])) != nil else {
            fatalError("Could not write the image to disk.")
        }

        return fileURL
    }

    func insertImage(_ image: UIImage) {

        let fileURL = saveToDisk(image: image)

        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange, sourceURL: fileURL, placeHolderImage: image)
        attachment.size = .full
        attachment.alignment = ImageAttachment.Alignment.none
        if let attachmentRange = richTextView.textStorage.ranges(forAttachment: attachment).first {
            richTextView.setLink(fileURL, inRange: attachmentRange)
        }
        let imageID = attachment.identifier
        let progress = Progress(parent: nil, userInfo: [MediaProgressKey.mediaID: imageID])
        progress.totalUnitCount = 100

        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MediaInsertionHelper.timerFireMethod(_:)), userInfo: progress, repeats: true)
    }

    func insertVideo(_ videoURL: URL) {
        let asset = AVURLAsset(url: videoURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        guard let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil) else {
            return
        }
        let posterImage = UIImage(cgImage: cgImage)
        let posterURL = saveToDisk(image: posterImage)
        let attachment = richTextView.replaceWithVideo(at: richTextView.selectedRange, sourceURL: URL(string:"placeholder://")!, posterURL: posterURL, placeHolderImage: posterImage)
        let mediaID = attachment.identifier
        let progress = Progress(parent: nil, userInfo: [MediaProgressKey.mediaID: mediaID, MediaProgressKey.videoURL:videoURL])
        progress.totalUnitCount = 100

        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MediaInsertionHelper.timerFireMethod(_:)), userInfo: progress, repeats: true)
    }

    @objc func timerFireMethod(_ timer: Timer) {
        guard let progress = timer.userInfo as? Progress,
              let imageId = progress.userInfo[MediaProgressKey.mediaID] as? String,
              let attachment = richTextView.attachment(withId: imageId)
        else {
            timer.invalidate()
            return
        }
        progress.completedUnitCount += 1

        attachment.progress = progress.fractionCompleted
        if mediaErrorMode && progress.fractionCompleted >= 0.25 {
            timer.invalidate()
            let message = NSAttributedString(string: "Upload failed!", attributes: mediaMessageAttributes)
            attachment.message = message
            attachment.overlayImage = Gridicon.iconOfType(.refresh)
        }
        if progress.fractionCompleted >= 1 {
            timer.invalidate()
            attachment.progress = nil
            if let videoAttachment = attachment as? VideoAttachment, let videoURL = progress.userInfo[MediaProgressKey.videoURL] as? URL {
                videoAttachment.updateURL(videoURL)
            }
        }
        richTextView.refresh(attachment, overlayUpdateOnly: true)
    }

}
