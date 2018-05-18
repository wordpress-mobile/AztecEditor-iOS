import Aztec

open class WordPressPlugin: Plugin {
    
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
    
    override open func process(inputHTML html: String) -> String {
        guard !isGutenbergContent(html) else {
            return html
        }
        
        return calypsoinputHTMLProcessor.process(html)
    }
    
    override open func process(outputHTML html: String) -> String {
        guard !isGutenbergContent(html) else {
            return html
        }
        
        return calypsoOutputHTMLProcessor.process(html)
    }
    
    // MARK: - Gutenberg support
    
    /// HACK: not a very good approach, but our APIs don't offer proper versioning info on `post_content`.
    /// Directly copied from here: https://github.com/WordPress/gutenberg/blob/5a6693589285363341bebad15bd56d9371cf8ecc/lib/register.php#L343
    ///
    func isGutenbergContent(_ content: String) -> Bool {
        return content.contains("<!-- wp:")
    }
}
