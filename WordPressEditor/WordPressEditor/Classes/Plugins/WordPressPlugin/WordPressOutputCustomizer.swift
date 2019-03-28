import Aztec
import UIKit

/// Ouptut customizer for the WordPress Plugin.
///
/// The Calypso processor is one that must DEFINITELY not be run on Gutenberg
/// posts.
///
/// The Gutenberg processors are harmless on Calypso posts.
///
open class WordPressOutputCustomizer: PluginOutputCustomizer {
    
    // MARK: - Calypso
    
    private let calypsoOutputHTMLProcessor = PipelineProcessor([
        CaptionShortcodeOutputProcessor(),
        VideoShortcodeProcessor.videoPressPostProcessor,
        VideoShortcodeProcessor.wordPressVideoPostProcessor,
        RemovePProcessor(),
        ])

    private let gutenbergOutputHTMLProcessor = PipelineProcessor([
        VideoShortcodeProcessor.videoPressPostProcessor,
        VideoShortcodeProcessor.wordPressVideoPostProcessor,
        ])
    
    // MARK: - Gutenberg
    
    private let isGutenbergContent: (String) -> Bool
    
    private let gutenbergOutputHTMLTreeProcessor = GutenbergOutputHTMLTreeProcessor()
    let attachmentToElementConverters: [BaseAttachmentToElementConverter] = [GalleryAttachmentToElementConverter(), GutenpackAttachmentToElementConverter()]
    let elementToTagConverters: [Element: ElementToTagConverter] = [.gallery: GalleryElementToTagConverter()]
    
    // MARK: - Initializers
    
    public required init(gutenbergContentVerifier isGutenbergContent: @escaping (String) -> Bool) {
        self.isGutenbergContent = isGutenbergContent
    }
    
    // MARK: - Output Processing
    
    open func process(html: String) -> String {
        guard !isGutenbergContent(html) else {
            return gutenbergOutputHTMLProcessor.process(html)
        }
        
        return calypsoOutputHTMLProcessor.process(html)
    }
    
    open func process(htmlTree: RootNode) {
        gutenbergOutputHTMLTreeProcessor.process(htmlTree)
    }
    
    open func convert(_ attachment: NSTextAttachment, attributes: [NSAttributedString.Key : Any]) -> [Node]? {
        for converter in attachmentToElementConverters {
            if let element = converter.convert(attachment, attributes: attributes) {
                return element
            }
        }
        
        return nil
    }
    
    open func converter(for elementNode: ElementNode) -> ElementToTagConverter? {
        guard let converter = elementToTagConverters[elementNode.type] else {
            return nil
        }
        
        return converter
    }
    
    // MARK: - AttributedStringParserCustomizer
    
    open func convert(_ paragraphProperty: ParagraphProperty) -> ElementNode? {
        guard let gutenblockProperty = paragraphProperty as? Gutenblock,
            let representation = gutenblockProperty.representation,
            case let .element(gutenblock) = representation.kind else {
                return nil
        }
        
        return gutenblock.toElementNode()
    }
}
