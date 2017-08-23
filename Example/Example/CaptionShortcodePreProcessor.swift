import Aztec
import Foundation

class CaptionShortcodePreProcessor: ShortcodeProcessor {

    init() {
        super.init(tag: "caption") { shortcode -> String in
            var html = "<div data-shortcode=\"caption\" "

            for (key, value) in shortcode.attributes.named {
                html += "\(key)=\"\(value)\" "
            }

            for value in shortcode.attributes.unamed {
                html += "\(value) "
            }

            if let content = shortcode.content {
                html += ">" + content + "</div>"
            } else {
                html += "/>"
            }
            
            return html
        }
    }
}
