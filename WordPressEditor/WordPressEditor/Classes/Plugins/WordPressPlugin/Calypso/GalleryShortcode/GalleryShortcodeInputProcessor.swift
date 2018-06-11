import Aztec
import Foundation

/// Handler Gallery Shortcodes pre-processing by converting them to <gallery> nodes.
///
class GalleryShortcodeInputProcessor: Processor {
    static let tag = "gallery"
    
    private lazy var galleryShortcodeProcessor: ShortcodeProcessor = {
        return ShortcodeProcessor(tag: GalleryShortcodeInputProcessor.tag) { [unowned self] (shortcode) -> String? in
            return self.process(shortcode)
        }
    }()
    
    let serializer = ShortcodeAttributeSerializer()
    
    // MARK: - Processor
    
    func process(_ text: String) -> String {
        return galleryShortcodeProcessor.process(text)
    }
    
    // MARK: - Gallery Tag Processing Logic
    
    func process(_ shortcode: Shortcode) -> String {
        let attributes = serializer.serialize(shortcode.attributes)
        
        return "<gallery \(attributes) />"
    }
}
