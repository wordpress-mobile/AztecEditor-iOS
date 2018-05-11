import XCTest
@testable import WordPressEditor

class GutenbergPreProcessorTests: XCTestCase {
    
    let processor = GutenbergPreProcessor()
    
    // MARK: Regular Gutenberg Tags
    
    private func encode(blockString: String) -> String {
        let data = blockString.data(using: .utf16)!
        let base64String = data.base64EncodedString()
        
        return base64String
    }
    
    /// Verifies that a Gutenberg paragraph block is properly encoded.
    ///
    func testParagraphBlock() {
        let openingGutentag = "<!-- wp:paragraph -->"
        let input = "\(openingGutentag)\n<p>Hello there!</p>\n<!-- /wp:paragraph -->"
        
        let encodedOpeningComment = encode(blockString: openingGutentag)
        let expected = "<gutenblock data=\"\(encodedOpeningComment)\">\n<p>Hello there!</p>\n</gutenblock>"
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
    }
    
    /// Verifies that a Gutenberg paragraph block with attributes is properly encoded.
    ///
    func testParagraphBlockWithAttributes() {
        let openingGutentag = "<!-- wp:paragraph {\"fontColor\": red, \"fontSize\": 12} -->"
        let input = "\(openingGutentag)\n<p>Hello there!</p>\n<!-- /wp:paragraph -->"
        
        let encodedOpeningComment = encode(blockString: openingGutentag)
        let expected = "<gutenblock data=\"\(encodedOpeningComment)\">\n<p>Hello there!</p>\n</gutenblock>"
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
    }
    
    /// Verifies that multiple Gutenberg paragraph blocks with attributes are properly encoded.
    ///
    func testMultipleParagraphBlocksWithAttributes() {
        let openingGutentag = "<!-- wp:paragraph {\"fontColor\": red, \"fontSize\": 12} -->"
        let singleInputParagraph = "\(openingGutentag)\n<p>Hello there!</p>\n<!-- /wp:paragraph -->"
        let input = String(format: "%@\n%@\n%@", singleInputParagraph, singleInputParagraph, singleInputParagraph)
        
        let encodedOpeningComment = encode(blockString: openingGutentag)
        let singleExpectedParagraph = "<gutenblock data=\"\(encodedOpeningComment)\">\n<p>Hello there!</p>\n</gutenblock>"
        let expected = String(format: "%@\n%@\n%@", singleExpectedParagraph, singleExpectedParagraph, singleExpectedParagraph)
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
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
}
