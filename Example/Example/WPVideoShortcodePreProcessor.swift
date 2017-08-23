import Aztec
import Foundation

class WPVideoShortcodePreProcessor: ShortcodeProcessor {

    init() {
        super.init(tag: "wpvideo") { (shortcode) in
            var html = "<video "
            if let src = shortcode.attributes.unamed.first {
                html += "src=\"videopress://\(src)\" "
                html += "data-wpvideopress=\"\(src)\" "
            }
            if let width = shortcode.attributes.named["w"] {
                html += "width=\(width) "
            }
            if let height = shortcode.attributes.named["h"] {
                html += "height=\(height) "
            }

            html += "/>"

            return html
        }
    }
}
