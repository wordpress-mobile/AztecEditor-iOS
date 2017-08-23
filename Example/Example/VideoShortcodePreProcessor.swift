import Aztec
import Foundation

class VideoShortcodePreProcessor: ShortcodeProcessor {

    init() {
        super.init(tag:"video") { (shortcode) in
            var html = "<video "
            for (key, value) in shortcode.attributes.named {
                html += "\(key)=\"\(value)\" "
            }
            for value in shortcode.attributes.unamed {
                html += "\(value) "
            }
            html += "/>"
            return html
        }
    }
}
