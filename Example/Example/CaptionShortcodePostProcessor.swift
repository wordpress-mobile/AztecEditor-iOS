import Aztec
import Foundation

class CaptionShortcodePostProcessor: Aztec.HTMLProcessor {

    init() {
        super.init(tag: "div") { (shortcode) in

            let dataShortcodeAttributeKey = "data-shortcode"

            guard let shortcodeType = shortcode.attributes.named[dataShortcodeAttributeKey],
                shortcodeType.lowercased() == "caption" else {
                    return nil
            }

            var html = "[caption "

            for (key, value) in shortcode.attributes.named where key != dataShortcodeAttributeKey {
                html += "\(key)=\"\(value)\" "
            }

            for value in shortcode.attributes.unamed {
                html += "\(value) "
            }

            html += "]" + (shortcode.content ?? "") + "[/caption]"
            
            return html
        }
    }
}
