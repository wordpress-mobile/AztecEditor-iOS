import Foundation
import UIKit


// MARK: - UIFont Emoji Helpers
//
extension UIFont {

    /// Indicates if the current font instance matches with iOS's Internal Emoji Font, or not.
    ///
    var isAppleEmojiFont: Bool {
        return fontName == ".AppleColorEmojiUI" || fontName == "AppleColorEmoji"
    }
}
