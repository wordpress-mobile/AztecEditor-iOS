import Aztec

/// Input customizer for the WordPress Plugin.
///
/// The Calypso processor is one that must DEFINITELY not be run on Gutenberg
/// posts.
///
/// The Gutenberg processors are harmless on Calypso posts.
///
open class WordPressInputCustomizer: PluginInputCustomizer {
    
    // MARK: - Calypso
    
    private let calypsoinputHTMLProcessor = PipelineProcessor([
        CaptionShortcodeInputProcessor(),
        GalleryShortcodeInputProcessor(),
        VideoShortcodeProcessor.videoPressPreProcessor,
        VideoShortcodeProcessor.wordPressVideoPreProcessor,
        AutoPProcessor()
        ])

    private let gutenbergInputHTMLProcessor = PipelineProcessor([
        VideoShortcodeProcessor.videoPressPreProcessor,
        VideoShortcodeProcessor.wordPressVideoPreProcessor
        ])
    
    // MARK: - Gutenberg
    
    private let isGutenbergContent: (String) -> Bool
    
    private let gutenbergInputHTMLTreeProcessor = GutenbergInputHTMLTreeProcessor()
    let inputElementConverters: [Element: ElementConverter] = [.gallery: GalleryElementConverter(),
                                                               .gutenblock: GutenblockConverter(),
                                                               .gutenpack: GutenpackConverter()]
    
    // MARK: - Initializers
    
    public required init(gutenbergContentVerifier isGutenbergContent: @escaping (String) -> Bool) {
        self.isGutenbergContent = isGutenbergContent
    }
    
    // MARK: - Input Processing
    
    open func process(html: String) -> String {
        guard !isGutenbergContent(html) else {
            return gutenbergInputHTMLProcessor.process(html)
        }
        
        return calypsoinputHTMLProcessor.process(html)
    }
    
    open func process(htmlTree: RootNode) {
        gutenbergInputHTMLTreeProcessor.process(htmlTree)
    }
    
    open func converter(for elementNode: ElementNode) -> ElementConverter? {
        guard let converter = inputElementConverters[elementNode.type] else {
            return nil
        }
        
        return converter
    }
}
