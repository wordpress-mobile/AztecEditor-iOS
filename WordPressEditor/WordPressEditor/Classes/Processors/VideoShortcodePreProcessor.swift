import Aztec
import Foundation

public class VideoShortcodePreProcessor: ShortcodeProcessor {

    public init() {
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
