import Aztec
import Foundation

public class VideoShortcodeProcessor {

    static public var videoPressScheme = "videopress"
    static public var videoPressHTMLAttribute = "data-wpvideopress"
    static public var videoWPShortcodeHTMLAttribute = "data-wpvideoshortcode"
    
    /// Shortcode processor to process videopress shortcodes to html video element
    /// More info here: https://en.support.wordpress.com/videopress/
    ///
    static var videoPressPreProcessor: Processor {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        let videoPressProcessor = ShortcodeProcessor(tag: "wpvideo", replacer: { (shortcode) in
            var html = "<video "

            let firstUnnamedAttribute = shortcode.attributes.first(where: { (shortcodeAttribute) -> Bool in
                guard case .nil = shortcodeAttribute.value else {
                    return false
                }
                
                return true
            })
            
            let src: String
            
            if let firstAttribute = firstUnnamedAttribute {
                src = shortcodeAttributeSerializer.serialize(firstAttribute)
            } else {
                src = ""
            }
            
            html += "src=\"\(videoPressScheme)://\(src)\" "
            html += "data-wpvideopress=\"\(src)\" "            

            if let width = shortcode.attributes["w"] {
                html += shortcodeAttributeSerializer.serialize(key: "width", value: width.value) + " "
            }

            if let height = shortcode.attributes["h"] {
                html += shortcodeAttributeSerializer.serialize(key: "height", value: height.value) + " "
            }

            if let uploadIDAttribute = shortcode.attributes[MediaAttachment.uploadKey] {
                html += shortcodeAttributeSerializer.serialize(uploadIDAttribute) + " "
            }

            html += "/>"

            return html
        })
        return videoPressProcessor
    }

    /// Shortcode processor to process html video elements to videopress shortcodes
    /// More info here: https://en.support.wordpress.com/videopress/
    ///
    static var videoPressPostProcessor: Processor {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        let postWordPressVideoProcessor = HTMLProcessor(for: "video", replacer: { (element) in
            
            guard let videoPressValue = element.attributes[videoPressHTMLAttribute]?.value,
                case let .string(videoPressID) = videoPressValue else {
                return nil
            }
            
            var html = "[wpvideo \(videoPressID) "
            
            if let width = element.attributes["width"] {
                html += shortcodeAttributeSerializer.serialize(key: "w", value: width.value) + " "
            }
            
            if let height = element.attributes["height"] {
                html += shortcodeAttributeSerializer.serialize(key: "h", value: height.value) + " "
            }
            
            if let uploadID = element.attributes[MediaAttachment.uploadKey] {
                html += shortcodeAttributeSerializer.serialize(uploadID) + " "
            }
            
            html += "]"
            
            return html
        })
        return postWordPressVideoProcessor
    }

    /// Shortcode processor to process wordpress videos shortcodes to html video element
    /// More info here: https://codex.wordpress.org/Video_Shortcode
    ///
    static var wordPressVideoPreProcessor: Processor {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        let wordPressVideoProcessor = ShortcodeProcessor(tag: "video", replacer: { (shortcode) in
            var html = "<video "
            
            if let src = shortcode.attributes["src"] {
                html += shortcodeAttributeSerializer.serialize(src) + " "
            }
            
            if let poster = shortcode.attributes["poster"] {
                html += shortcodeAttributeSerializer.serialize(poster) + " "
            }
            
            if let uploadID = shortcode.attributes[MediaAttachment.uploadKey] {
                html += shortcodeAttributeSerializer.serialize(uploadID) + " "
            }

            html += shortcodeAttributeSerializer.serialize(ShortcodeAttribute(key: videoWPShortcodeHTMLAttribute, value: "true")) + " "
            
            html += "/>"
            
            return html
        })
        return wordPressVideoProcessor
    }

    /// Shortcode processor to process html video elements to wordpress videos shortcodes
    /// More info here: https://codex.wordpress.org/Video_Shortcode
    ///
    static var wordPressVideoPostProcessor: Processor {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        let postWordPressVideoProcessor = HTMLProcessor(for: "video", replacer: { (element) in

            guard element.attributes[videoWPShortcodeHTMLAttribute]?.value != nil else {
                    return nil
            }

            var html = "[video "
            
            if let src = element.attributes["src"] {
                html += shortcodeAttributeSerializer.serialize(src) + " "
            }
            
            if let posterAttribute = element.attributes["poster"],
                case let .string(posterValue) = posterAttribute.value,
                let posterURL = URL(string: posterValue),
                !posterURL.isFileURL {
                
                html += shortcodeAttributeSerializer.serialize(posterAttribute) + " "
            }
            
            if let uploadID = element.attributes[MediaAttachment.uploadKey] {
                html += shortcodeAttributeSerializer.serialize(uploadID) + " "
            }
            
            html += "]"
            
            return html
        })
        return postWordPressVideoProcessor
    }
}
