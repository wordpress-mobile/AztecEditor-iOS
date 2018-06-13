import Aztec

/// Plugins that implements all of the WordPress specific HTML customizations.
///
/// The Calypso processor is one that must DEFINITELY not be run on Gutenberg
/// posts.
///
/// The Gutenberg processors are harmless on Calypso posts.
///
open class WordPressPlugin: Plugin {
    
    typealias GutenbergContentVerifier = (String) -> Bool
    
    public init() {
        let isGutenbergContent: GutenbergContentVerifier = { content -> Bool in
            return content.contains("<!-- wp:")
        }
        
        super.init(
            inputCustomizer: WordPressInputCustomizer(gutenbergContentVerifier: isGutenbergContent),
            outputCustomizer: WordPressOutputCustomizer(gutenbergContentVerifier: isGutenbergContent))
    }
}
