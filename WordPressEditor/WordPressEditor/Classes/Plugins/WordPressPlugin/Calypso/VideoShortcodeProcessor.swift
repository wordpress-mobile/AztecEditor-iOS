import Aztec
import Foundation

public class VideoShortcodeProcessor {

    static public var videoPressScheme = "videopress"
    static public var videoPressHTMLAttribute = "data-wpvideopress"
    
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
            html += "poster=\"\(videoPressScheme)://\(src)\" "

            if let width = shortcode.attributes["w"] {
                html += shortcodeAttributeSerializer.serialize(key: "width", value: width) + " "
            }

            if let height = shortcode.attributes["h"] {
                html += shortcodeAttributeSerializer.serialize(key: "height", value: height) + " "
            }

            if let uploadIDAttribute = shortcode.attributes[MediaAttachment.uploadKey] {
                html += shortcodeAttributeSerializer.serialize(key: MediaAttachment.uploadKey, value: uploadIDAttribute) + " "
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
        
        let postWordPressVideoProcessor = HTMLProcessor(tag: "video", replacer: { (element) in
            
            guard let videoPressID = element.attributes[videoPressHTMLAttribute] else {
                return nil
            }
            
            var html = "[wpvideo \(videoPressID) "
            
            if let width = element.attributes["width"] {
                html += shortcodeAttributeSerializer.serialize(key: "w", value: width) + " "
            }
            
            if let height = element.attributes["height"] {
                html += shortcodeAttributeSerializer.serialize(key: "h", value: height) + " "
            }
            
            if let uploadID = element.attributes[MediaAttachment.uploadKey] {
                html += shortcodeAttributeSerializer.serialize(key: MediaAttachment.uploadKey, value: uploadID) + " "
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
                html += shortcodeAttributeSerializer.serialize(key: "src", value: src) + " "
            }
            
            if let poster = shortcode.attributes["poster"] {
                html += shortcodeAttributeSerializer.serialize(key: "poster", value: poster) + " "
            }
            
            if let uploadID = shortcode.attributes[MediaAttachment.uploadKey] {
                html += shortcodeAttributeSerializer.serialize(key: MediaAttachment.uploadKey, value: uploadID) + " "
            }
            
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
        
        let postWordPressVideoProcessor = HTMLProcessor(tag: "video", replacer: { (element) in
            var html = "[video "
            
            if let src = element.attributes["src"] {
                html += shortcodeAttributeSerializer.serialize(key: "src", value: src) + " "
            }
            
            if let posterAttribute = element.attributes["poster"],
                case let .string(posterValue) = posterAttribute,
                let posterURL = URL(string: posterValue),
                !posterURL.isFileURL {
                
                html += shortcodeAttributeSerializer.serialize(key: "poster", value: posterAttribute) + " "
            }
            
            if let uploadID = element.attributes[MediaAttachment.uploadKey] {
                html += shortcodeAttributeSerializer.serialize(key: MediaAttachment.uploadKey, value: uploadID) + " "
            }
            
            html += "]"
            
            return html
        })
        return postWordPressVideoProcessor
    }
}
