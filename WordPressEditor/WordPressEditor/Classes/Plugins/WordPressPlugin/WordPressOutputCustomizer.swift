import Aztec

/// Plugins that implements all of the WordPress specific HTML customizations.
///
/// The Calypso processor is one that must DEFINITELY not be run on Gutenberg
/// posts.
///
/// The Gutenberg processors are harmless on Calypso posts.
///
open class WordPressOutputCustomizer: Plugin.OutputCustomizer {
    
    // MARK: - Calypso
    
    private let calypsoOutputHTMLProcessor = PipelineProcessor([
        CaptionShortcodeOutputProcessor(),
        VideoShortcodeProcessor.videoPressPostProcessor,
        VideoShortcodeProcessor.wordPressVideoPostProcessor,
        RemovePProcessor(),
        ])
    
    // MARK: - Gutenberg
    
    private let isGutenbergContent: (String) -> Bool
    
    private let gutenbergOutputHTMLTreeProcessor = GutenbergOutputHTMLTreeProcessor()
    
    // MARK: - Initializers
    
    public required init(gutenbergContentVerifier isGutenbergContent: @escaping (String) -> Bool) {
        self.isGutenbergContent = isGutenbergContent
        
        super.init()
    }
    
    // MARK: - Output Processing
    
    override open func process(outputHTML html: String) -> String {
        guard !isGutenbergContent(html) else {
            return html
        }
        
        return calypsoOutputHTMLProcessor.process(html)
    }
    
    override open func process(outputHTMLTree tree: RootNode) {
        gutenbergOutputHTMLTreeProcessor.process(tree)
    }
    
    // MARK: - AttributedStringParserCustomizer
    
    override open func convert(_ paragraphProperty: ParagraphProperty) -> ElementNode? {
        guard let gutenblockProperty = paragraphProperty as? Gutenblock,
            let representation = gutenblockProperty.representation,
            case let .element(gutenblock) = representation.kind else {
                return nil
        }
        
        return gutenblock.toElementNode()
    }
}
