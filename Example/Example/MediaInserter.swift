import Foundation
import UIKit
import Aztec
import AVFoundation

class MediaInserter
{
    fileprivate var mediaErrorMode = false

    struct MediaProgressKey {
        static let mediaID = ProgressUserInfoKey("mediaID")
        static let videoURL = ProgressUserInfoKey("videoURL")
    }
    
    let richTextView: TextView

    var attachmentTextAttributes: [NSAttributedString.Key: Any]

    init(textView: TextView, attachmentTextAttributes: [NSAttributedString.Key: Any]) {
        self.richTextView = textView
        self.attachmentTextAttributes = attachmentTextAttributes
    }

    func insertImage(_ image: UIImage) {

        let fileURL = image.saveToTemporaryFile()

        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange, sourceURL: fileURL, placeHolderImage: image)
        attachment.size = .full
        attachment.alignment = ImageAttachment.Alignment.none
        if let attachmentRange = richTextView.textStorage.ranges(forAttachment: attachment).first {
            richTextView.setLink(fileURL, inRange: attachmentRange)
        }
        let imageID = attachment.identifier
        let progress = Progress(parent: nil, userInfo: [MediaProgressKey.mediaID: imageID])
        progress.totalUnitCount = 100

        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MediaInserter.timerFireMethod(_:)), userInfo: progress, repeats: true)
    }

    func insertVideo(_ videoURL: URL) {
        let asset = AVURLAsset(url: videoURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        guard let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil) else {
            return
        }
        let posterImage = UIImage(cgImage: cgImage)
        let posterURL = posterImage.saveToTemporaryFile()
        let attachment = richTextView.replaceWithVideo(at: richTextView.selectedRange, sourceURL: URL(string:"placeholder://")!, posterURL: posterURL, placeHolderImage: posterImage)
        let mediaID = attachment.identifier
        let progress = Progress(parent: nil, userInfo: [MediaProgressKey.mediaID: mediaID, MediaProgressKey.videoURL:videoURL])
        progress.totalUnitCount = 100

        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MediaInserter.timerFireMethod(_:)), userInfo: progress, repeats: true)
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
            let message = NSAttributedString(string: "Upload failed!", attributes: attachmentTextAttributes)
            attachment.message = message
            attachment.overlayImage = UIImage.systemImage("arrow.clockwise")
        }
        if progress.fractionCompleted >= 1 {
            timer.invalidate()
            attachment.progress = nil
            if let videoAttachment = attachment as? VideoAttachment, let videoURL = progress.userInfo[MediaProgressKey.videoURL] as? URL {
                videoAttachment.updateURL(videoURL, refreshAsset: false)
            }
        }
        richTextView.refresh(attachment, overlayUpdateOnly: true)
    }

}
