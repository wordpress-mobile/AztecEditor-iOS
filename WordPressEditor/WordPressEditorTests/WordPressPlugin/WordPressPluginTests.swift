@testable import Aztec
@testable import WordPressEditor

import Foundation
import XCTest

fileprivate let emptyImage = UIImage(data: Data(base64Encoded: "R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==")!)!

class WordpressPluginTests: XCTestCase {
    
    let pluginManager: PluginManager = {
        let pluginManager = PluginManager()
        let systemFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        let textView = TextView(defaultFont: systemFont, defaultMissingImage: emptyImage)
        
        pluginManager.load(WordPressPlugin(), in: textView)

        return pluginManager
    }()
    
    lazy var htmlConverter: HTMLConverter = {
        return HTMLConverter(with: pluginManager)
    }()
    
    lazy var treeToAttributedString = {
        return AttributedStringSerializer(customizer: pluginManager)
    }()
    
    lazy var attributedStringToTree = {
        return AttributedStringParser(customizer: pluginManager)
    }()
    
    func testThatRoundConversion(fromInputHTML inputHTML: String, resultsInOutputHTML expectedHTML: String) {
        let attributedString = htmlConverter.attributedString(from: inputHTML)
        let outputHtml = htmlConverter.html(from: attributedString)
        
        XCTAssertEqual(outputHtml, expectedHTML)
    }
    
    // MARK: - Full Conversion
    
    func testFullConversionOfParagraphBlock() {
        let initialHTML = "<!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph -->"
        let expectedHTML = initialHTML
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString)
        
        XCTAssertEqual(finalHTML, expectedHTML)
    }
    
    func testFullConversionOfMultipleParagraphBlocks() {
        let initialHTML = "<!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph --><!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph --><!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph -->"
        let expectedHTML = "<!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph -->\n<!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph -->\n<!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph -->"
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString)
        
        XCTAssertEqual(finalHTML, expectedHTML)
    }
    
    func testFullConversionOfMultipleParagraphForCalypso() {
        let initialHTML = "<p>Hello 🌍!</p><p>Hello 🌍!</p><p>Hello 🌍!</p>"
        let expectedHTML = "Hello 🌍!\n\nHello 🌍!\n\nHello 🌍!"
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString)
        
        XCTAssertEqual(finalHTML, expectedHTML)
    }

    // MARK: - Full Conversion, beautified
    
    func testFullConversionOfParagraphBlockBeautified() {        
        let initialHTML = "<!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph -->"
        let expectedHTML = "<!-- wp:paragraph -->\n<p>Hello 🌍!</p>\n<!-- /wp:paragraph -->"
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString, prettify: true)
        
        XCTAssertEqual(finalHTML, expectedHTML)
    }
    
    // MARK: - Gutenblock Conversion
    
    func testGutenblockToAttrStringAndBack() {
        let text = "Hello 🌍!"
        let textNode = TextNode(text: text)
        let paragraphElement = ElementNode(type: .p, attributes: [], children: [textNode])
        let gutenblock = ElementNode(type: .gutenblock, attributes: [], children: [paragraphElement])
        
        let outputAttrString = treeToAttributedString.serialize(gutenblock)
        XCTAssertEqual(outputAttrString.string, text)
        
        guard let paragraphStyle = outputAttrString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? ParagraphStyle else {
            XCTFail()
            return
        }
        
        XCTAssert(paragraphStyle.properties.contains(where: { $0 is Gutenblock }))
        
        let rootNode = attributedStringToTree.parse(outputAttrString)
        
        guard let outputGutenblock = rootNode.firstChild(ofType: .gutenblock) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(outputGutenblock.children.count, 1)
        
        guard let outputParagraph = outputGutenblock.firstChild(ofType: .p) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(outputParagraph.children.count, 1)
        
        guard let outputTextNode = outputParagraph.children.first as? TextNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(outputTextNode.text(), text)
    }

    // MARK: - Test merging of gutenberg block

    func testMergingOfListBlockWithMultipleListElements() {
        let initialHTML = """
<!-- wp:list -->
<ul>
  <li>Media library/HTML for images, multimedia and approved files.</li>
  <li>Pasted links for embeds.</li>
  <li>Shortcodes for specialized assets from plugins.</li>
  <li>Featured images for the image at the top of a post or page.</li>
  <li>Excerpts for subheads.</li>
  <li>Widgets for content on the side of a page.</li>
</ul>
<!-- /wp:list -->
"""
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString, prettify: true)

        XCTAssertEqual(finalHTML, initialHTML)
    }

    func testMerginOfBlockquoteBlockWithMultipleLinesElements() {
        let initialHTML = """
<!-- wp:quote -->
<blockquote class="wp-block-quote is-large">
  <p>Take comfort in the fact that you 'can' keep your current publishing flow... </p>
  <p>and then take some time to explore the possibilities that Gutenberg opens up to you.</p>
</blockquote>
<!-- /wp:quote -->
"""
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString, prettify: true)

        XCTAssertEqual(finalHTML, initialHTML)
    }

    func testMerginOfMultipleParagraphsElements() {
        let initialHTML = """
<!-- wp:paragraph -->
<p>Take comfort in the fact that you 'can' keep your current publishing flow... </p>
<!-- /wp:paragraph -->
<!-- wp:paragraph -->
<p>and then take some time to explore the possibilities that Gutenberg opens up to you.</p>
<!-- /wp:paragraph -->
"""
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString, prettify: true)

        XCTAssertEqual(finalHTML, initialHTML)
    }

    func testSelfClosingGutenbergBlock() {
        let initialHTML = "<!-- wp:latest-posts /-->"
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString, prettify: true)

        XCTAssertEqual(finalHTML, initialHTML)
    }

    func testGutenbergBlockNotClosed() {
        let initialHTML = """
<!-- wp:list -->
<ul>
  <li>Media library/HTML for images, multimedia and approved files.</li>
</ul>
"""
    
        // The input would ideally match the output, but unfortunately we can't avoid P elements from
        // wrapping non-closed gutenberg tags at this time.
        let expected = """
<p><!-- wp:list --></p>
<ul>
  <li>Media library/HTML for images, multimedia and approved files.</li>
</ul>
"""
        
        let attrString = htmlConverter.attributedString(from: initialHTML)
        let finalHTML = htmlConverter.html(from: attrString, prettify: true)

        XCTAssertEqual(finalHTML, expected)
    }
    
    // MARK: - Gutenpack + Gutenblock
    
    /// Spawned from: https://github.com/wordpress-mobile/AztecEditor-iOS/pull/1116#issuecomment-449056392
    ///
    func testGutenpackAddsNewlineInVisualModeIfNeeded() {
        
        let html = """
<!-- wp:latestposts /-->

<!-- wp:separator -->
<hr class="wp-block-separator">
<!-- /wp:separator -->
"""
        let expectedOutput = """
<!-- wp:latestposts /-->
<!-- wp:separator --><hr class="wp-block-separator"><!-- /wp:separator -->
"""
        
        testThatRoundConversion(fromInputHTML: html, resultsInOutputHTML: expectedOutput)
    }
    
    /// Spawned from: https://github.com/wordpress-mobile/AztecEditor-iOS/pull/1116#issuecomment-449064390
    ///
    func testGutenpackAddsNewlineInVisualModeIfNeeded2() {
        let html = """
<!-- wp:separator -->
<hr class="wp-block-separator" />
<!-- /wp:separator -->

<!-- wp:video -->
<figure class="wp-block-video"><video controls src="https://videos.files.wordpress.com/AvC6H2JI/video-de223da1f6.mp4"></video></figure>
<!-- /wp:video -->
"""
        let expectedOutput = """
<!-- wp:separator --><hr class="wp-block-separator"><!-- /wp:separator -->
<!-- wp:video --><figure class="wp-block-video"><video src="https://videos.files.wordpress.com/AvC6H2JI/video-de223da1f6.mp4"></video></figure><!-- /wp:video -->
"""
        
        testThatRoundConversion(fromInputHTML: html, resultsInOutputHTML: expectedOutput)
    }
    

    /// Spawned from: https://github.com/wordpress-mobile/AztecEditor-iOS/pull/1116#issuecomment-449064390
    ///
    func testGutenpackAddsNewlineInVisualModeIfNeeded3() {
        let html = """
<!-- wp:video -->
<figure class="wp-block-video"><video src="https://videos.files.wordpress.com/AvC6H2JI/video-de223da1f6.mp4"></video></figure>
<!-- /wp:video -->

<!-- wp:separator -->
<hr class="wp-block-separator" />
<!-- /wp:separator -->
"""
        let expectedOutput = """
<!-- wp:video --><figure class="wp-block-video"><video src="https://videos.files.wordpress.com/AvC6H2JI/video-de223da1f6.mp4"></video></figure><!-- /wp:video -->
<!-- wp:separator --><hr class="wp-block-separator"><!-- /wp:separator -->
"""
        
        testThatRoundConversion(fromInputHTML: html, resultsInOutputHTML: expectedOutput)
    }
    
    // MARK: - Spacer Block
    
    /// This test was spawned off this issue:
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/1078
    ///
    /// Spacer blocks are not being properly parsed and are being stripped from posts.
    ///
    func testSpacerBlockNotRemoved() {
        let spacerBlock = "<!-- wp:spacer --><div style=\"height: 100px\" aria-hidden=\"true\" class=\"wp-block-spacer\"></div><!-- /wp:spacer -->"
        
        let attributedString = htmlConverter.attributedString(from: spacerBlock)
        let finalHTML = htmlConverter.html(from: attributedString)
        
        XCTAssertEqual(finalHTML, spacerBlock)
    }
    
    // MARK: - Non-breaking spaces.
    
    func testNonBreakingSpacesAreProperlyEncoded() {
        let html = "<p>&nbsp;&nbsp;</p><p>&nbsp;<br>&nbsp;</p>"
        let expected = "&nbsp;&nbsp;\n\n&nbsp;\n&nbsp;"
        
        let attributedString = htmlConverter.attributedString(from: html)
        let finalHTML = htmlConverter.html(from: attributedString)
        
        XCTAssertEqual(finalHTML, expected)
    }
}

