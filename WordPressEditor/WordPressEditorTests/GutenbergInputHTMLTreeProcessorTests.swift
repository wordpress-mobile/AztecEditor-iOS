import Aztec
import XCTest
@testable import WordPressEditor

class GutenbergInputHTMLTreeProcessorTests: XCTestCase {
    
    let parser = HTMLParser()
    let processor = GutenbergInputHTMLTreeProcessor()
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    // MARK: Regular Gutenberg Tags
    
    private func encode(blockString: String) -> String {
        let data = blockString.data(using: .utf16)!
        let base64String = data.base64EncodedString()
        
        return base64String
    }
    
    private func htmlComment(withContent content: String) -> String {
        return "<!--\(content)-->"
    }
    
    /// Verifies that a Gutenberg paragraph block is properly encoded.
    ///
    func testParagraphBlock() {
        let openingCommentText = " wp:paragraph "
        let closingCommentText = " /wp:paragraph "
        let openingGutentag = htmlComment(withContent: openingCommentText)
        let closingGutentag = htmlComment(withContent: closingCommentText)
        let text = "Hello there!"
        
        let input = "\(openingGutentag)\n<p>\(text)</p>\n\(closingGutentag)"
        
        let encodedOpeningComment = encode(blockString: openingCommentText)
        let encodedClosingComment = encode(blockString: closingCommentText)
        
        let rootNode = parser.parse(input)
        processor.process(rootNode)
        
        XCTAssertEqual(rootNode.children.count, 1)
        guard let gutenblock = rootNode.children[0] as? ElementNode,
            gutenblock.type == .gutenblock else {
                XCTFail()
                return
        }
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockOpener
                && attribute.value.toString() == encodedOpeningComment
        }))
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockCloser
                && attribute.value.toString() == encodedClosingComment
        }))
        
        XCTAssertEqual(gutenblock.children.count, 2)
        guard let paragraph = gutenblock.children[0] as? ElementNode else {
            XCTFail()
            return
        }

        XCTAssertEqual(paragraph.children.count, 1)
        guard let textNode = paragraph.children[0] as? TextNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(textNode.text(), text)
    }
    
    /// Verifies that a Gutenberg paragraph block with attributes is properly encoded.
    ///
    func testParagraphBlockWithAttributes() {
        let openingCommentText = " wp:paragraph {\"fontColor\": red, \"fontSize\": 12}"
        let closingCommentText = " /wp:paragraph "
        let openingGutentag = htmlComment(withContent: openingCommentText)
        let closingGutentag = htmlComment(withContent: closingCommentText)
        let text = "Hello there!"
        
        let input = "\(openingGutentag)\n<p>\(text)</p>\n\(closingGutentag)"
        
        let encodedOpeningComment = encode(blockString: openingCommentText)
        let encodedClosingComment = encode(blockString: closingCommentText)
        
        let rootNode = parser.parse(input)
        processor.process(rootNode)
        
        XCTAssertEqual(rootNode.children.count, 1)
        guard let gutenblock = rootNode.children[0] as? ElementNode,
            gutenblock.type == .gutenblock else {
                XCTFail()
                return
        }
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockOpener
                && attribute.value.toString() == encodedOpeningComment
        }))
        
        XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
            return attribute.name == GutenbergAttributeNames.blockCloser
                && attribute.value.toString() == encodedClosingComment
        }))
        
        XCTAssertEqual(gutenblock.children.count, 2)
        guard let paragraph = gutenblock.children[0] as? ElementNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(paragraph.children.count, 1)
        guard let textNode = paragraph.children[0] as? TextNode else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(textNode.text(), text)
    }
    /*
    /// Verifies that multiple Gutenberg paragraph blocks with attributes are properly encoded.
    ///
    func testMultipleParagraphBlocksWithAttributes() {
        let openingCommentText = " wp:paragraph {\"fontColor\": red, \"fontSize\": 12}"
        let closingCommentText = " /wp:paragraph "
        let openingGutentag = htmlComment(withContent: openingCommentText)
        let closingGutentag = htmlComment(withContent: closingCommentText)
        let text = "Hello 🌎!"
        
        let singleInputParagraph = "\(openingGutentag)\n<p>\(text)</p>\n\(closingGutentag)"
        let input = String(format: "%@\n%@\n%@", singleInputParagraph, singleInputParagraph, singleInputParagraph)
        
        let encodedOpeningComment = encode(blockString: openingCommentText)
        let encodedClosingComment = encode(blockString: closingCommentText)
        
        let rootNode = parser.parse(input)
        processor.process(rootNode)
        
        XCTAssertEqual(rootNode.children.count, 3)
        
        for child in rootNode.children {
            guard let gutenblock = child as? ElementNode,
                gutenblock.type == .gutenblock else {
                    XCTFail()
                    return
            }
            
            XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
                return attribute.name == GutenbergAttributeNames.blockOpener
                    && attribute.value.toString() == encodedOpeningComment
            }))
            
            XCTAssert(gutenblock.attributes.contains(where: { (attribute) -> Bool in
                return attribute.name == GutenbergAttributeNames.blockCloser
                    && attribute.value.toString() == encodedClosingComment
            }))
            
            XCTAssertEqual(gutenblock.children.count, 2)
            guard let paragraph = gutenblock.children[0] as? ElementNode else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(paragraph.children.count, 1)
            guard let textNode = paragraph.children[0] as? TextNode else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(textNode.text(), text)
        }
    }

    // MARK: - Self-Closing Gutenberg Tags
    
    /// Verifies that a self closing block is properly processed
    ///
    func testSelfClosedBlock() {
        let input = "<!-- wp:latest-posts /-->"
        
        let encodedGutentag = encode(blockString: input)
        let expected = "<gutenblock data=\"\(encodedGutentag)\">"
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
    }
    
    /// Verifies that a self closing block with attributes is properly processed
    ///
    func testSelfClosedBlockWithAttributes() {
        let input = "<!-- wp:latest-posts {\"postsToShow\":4,\"displayPostDate\":true} /-->"
        
        let encodedGutentag = encode(blockString: input)
        let expected = "<gutenblock data=\"\(encodedGutentag)\">"
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
    }
    
    
    /// Verifies that multiple self closing blocks with attributes are properly processed
    ///
    func testMultipleSelfClosedBlockWithAttributes() {
        let singleGutentag = "<!-- wp:latest-posts {\"postsToShow\":4,\"displayPostDate\":true} /-->"
        let input = String(format: "%@\n%@\n%@", singleGutentag, singleGutentag, singleGutentag)
        
        let encodedGutentag = encode(blockString: singleGutentag)
        let singleExpectedElement = "<gutenblock data=\"\(encodedGutentag)\">"
        let expected = String(format: "%@\n%@\n%@", singleExpectedElement, singleExpectedElement, singleExpectedElement)
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
    }
 */
}
