import Foundation
import Aztec


// MARK: - VideoAttachment
//
extension VideoAttachment {

    @objc public var videoPressID: String? {
        get {
            return extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute]?.toString()
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes[VideoShortcodeProcessor.videoPressHTMLAttribute] = .string(nonNilValue)
            } else {
                extraAttributes.remove(named: VideoShortcodeProcessor.videoPressHTMLAttribute)
            }
        }
    }

    @objc public var isShortcode: Bool {
        get {
            return extraAttributes[VideoShortcodeProcessor.videoWPShortcodeHTMLAttribute]?.toString() == "true"
        }
        set {
            if newValue {
                extraAttributes[VideoShortcodeProcessor.videoWPShortcodeHTMLAttribute] = .string(String("true"))
            } else {
                extraAttributes.remove(named: VideoShortcodeProcessor.videoWPShortcodeHTMLAttribute)
            }
        }
    }
}
