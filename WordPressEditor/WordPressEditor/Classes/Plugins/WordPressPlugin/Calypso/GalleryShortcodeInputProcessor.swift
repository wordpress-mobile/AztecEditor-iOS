import Aztec
import Foundation

/// Handler Gallery Shortcodes pre-processing by converting them to <gallery> nodes.
///
class GalleryShortcodeInputProcessor: Processor {
    static let tag = "gallery"
    private static let attributeSeparator = " "
    
    private lazy var galleryShortcodeProcessor: ShortcodeProcessor = {
        return ShortcodeProcessor(tag: GalleryShortcodeInputProcessor.tag) { [unowned self] (shortcode) -> String? in
            return self.process(shortcode)
        }
    }()
    
    // MARK: - Processor
    
    func process(_ text: String) -> String {
        return galleryShortcodeProcessor.process(text)
    }
    
    // MARK: - Gallery Tag Processing Logic
    
    func process(_ shortcode: Shortcode) -> String {
        let attributes = process(shortcode.attributes)
        
        return "<gallery \(attributes)>"
    }
    
    func process(_ attributes: HTMLAttributes) -> String {
        let namedAttributes = attributes.named.map({ (key, value) -> String in
            return "\(key)=\"\(value)\""
        })
        
        let allAttributes = attributes.unamed + namedAttributes
        
        return allAttributes.joined(separator: GalleryShortcodeInputProcessor.attributeSeparator)
    }
}
