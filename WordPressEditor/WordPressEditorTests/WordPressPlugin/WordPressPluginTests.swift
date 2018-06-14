@testable import Aztec
@testable import WordPressEditor

import Foundation
import XCTest

class WordpressPluginTests: XCTestCase {
    
    let pluginManager: PluginManager = {
        let pluginManager = PluginManager()
        
        pluginManager.load(WordPressPlugin())
        
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
    
    // MARK: - Full Conversion
    
    func testFullConversionOfParagraphBlock() {
        let initialHTML = "<!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph -->"
        let expectedHTML = "<!-- wp:paragraph --><p>Hello 🌍!</p><!-- /wp:paragraph -->"
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
}

