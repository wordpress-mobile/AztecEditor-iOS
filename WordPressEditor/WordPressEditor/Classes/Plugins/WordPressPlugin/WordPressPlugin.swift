import Aztec

/// Plugins that implements all of the WordPress specific HTML customizations.
///
/// The Calypso processor is one that must DEFINITELY not be run on Gutenberg
/// posts.
///
/// The Gutenberg processors are harmless on Calypso posts.
///
open class WordPressPlugin: Plugin {
    
    // MARK: - Calypso Processors
    
    private let calypsoinputHTMLProcessor = PipelineProcessor([
        CaptionShortcodeInputProcessor(),
        VideoShortcodeProcessor.videoPressPreProcessor,
        VideoShortcodeProcessor.wordPressVideoPreProcessor,
        AutoPProcessor()
        ])
    
    private let calypsoOutputHTMLProcessor = PipelineProcessor([
        CaptionShortcodeOutputProcessor(),
        VideoShortcodeProcessor.videoPressPostProcessor,
        VideoShortcodeProcessor.wordPressVideoPostProcessor,
        RemovePProcessor(),
        ])
    
    // MARK: - Gutenberg processors
    
    private let gutenbergInputHTMLTreeProcessor = GutenbergInputHTMLTreeProcessor()
    private let gutenbergOutputHTMLTreeProcessor = GutenbergOutputHTMLTreeProcessor()
    
    // MARK: - Gutenberg Converters
    
    let gutenergInputConverter = GutenblockConverter()
    
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
    
    override open func inputElementConverters() -> [Element: ElementConverter] {
        return [.gutenblock: gutenergInputConverter]
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
    
    // MARK: - Gutenberg support
    
    /// HACK: not a very good approach, but our APIs don't offer proper versioning info on `post_content`.
    /// Directly copied from here: https://github.com/WordPress/gutenberg/blob/5a6693589285363341bebad15bd56d9371cf8ecc/lib/register.php#L343
    ///
    private func isGutenbergContent(_ content: String) -> Bool {
        return content.contains("<!-- wp:")
    }
}
