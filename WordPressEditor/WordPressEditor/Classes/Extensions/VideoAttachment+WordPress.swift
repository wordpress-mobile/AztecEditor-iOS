import Foundation
import Aztec


// MARK: - VideoAttachment
//
extension VideoAttachment {

    @objc var videoPressID: String? {
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
}
