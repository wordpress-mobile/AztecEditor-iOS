import Foundation
import Aztec


// MARK: - MediaAttachment
//
extension MediaAttachment {

    public static let uploadKey = "data-wp_upload_id"

    public var uploadID: String? {
        get {
            return extraAttributes[MediaAttachment.uploadKey]?.toString()
        }
        set {
            if let nonNilValue = newValue {
                extraAttributes[MediaAttachment.uploadKey] = .string(nonNilValue)
            } else {
                extraAttributes.remove(named: MediaAttachment.uploadKey)
            }
        }
    }
}
