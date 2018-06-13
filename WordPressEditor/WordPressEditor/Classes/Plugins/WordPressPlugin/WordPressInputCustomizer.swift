import Aztec

/// Plugins that implements all of the WordPress specific HTML customizations.
///
/// The Calypso processor is one that must DEFINITELY not be run on Gutenberg
/// posts.
///
/// The Gutenberg processors are harmless on Calypso posts.
///
open class WordPressInputCustomizer: Plugin.InputCustomizer {
    
    // MARK: - Calypso
    
    private let calypsoinputHTMLProcessor = PipelineProcessor([
        CaptionShortcodeInputProcessor(),
        GalleryShortcodeInputProcessor(),
        VideoShortcodeProcessor.videoPressPreProcessor,
        VideoShortcodeProcessor.wordPressVideoPreProcessor,
        AutoPProcessor()
        ])
    
    // MARK: - Gutenberg
    
    private let isGutenbergContent: (String) -> Bool
    
    private let gutenbergInputHTMLTreeProcessor = GutenbergInputHTMLTreeProcessor()
    let inputElementConverters: [Element: ElementConverter] = [.gallery: GalleryElementConverter(),
                                                               .gutenblock: GutenblockConverter()]
    
    // MARK: - Initializers
    
    public required init(gutenbergContentVerifier isGutenbergContent: @escaping (String) -> Bool) {
        self.isGutenbergContent = isGutenbergContent
        
        super.init()
    }
    
    // MARK: - Input Processing
    
    override open func process(inputHTML html: String) -> String {
        guard !isGutenbergContent(html) else {
            return html
        }
        
        return calypsoinputHTMLProcessor.process(html)
    }
    
    override open func process(inputHTMLTree tree: RootNode) {
        gutenbergInputHTMLTreeProcessor.process(tree)
    }
    
    override open func converter(for elementNode: ElementNode) -> ElementConverter? {
        guard let converter = inputElementConverters[elementNode.type] else {
            return nil
        }
        
        return converter
    }
}
