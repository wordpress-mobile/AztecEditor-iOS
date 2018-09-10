import Aztec
import XCTest
@testable import WordPressEditor

class GutenbergOutputHTMLTreeProcessorTests: XCTestCase {
    
    let parser = HTMLParser()
    let processor = GutenbergOutputHTMLTreeProcessor()
    private let encoder = GutenbergAttributeEncoder()
    private let decoder = GutenbergAttributeDecoder()
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    /// There was an issue with Gutenberg posts losing edits.  This automated test makes sure the issues we found don't regress.
    ///
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/1052
    ///
    func testDataLossWhenProcessing() {
        
        let commentNode = CommentNode(text: "wp:latestposts /")
        let gutenpackAttribute = encoder.selfClosingAttribute(for: commentNode)
        let gutenpack = ElementNode(type: .gutenpack, attributes: [gutenpackAttribute], children: [])
        let text = TextNode(text: "This text will be lost")
        let paragraph = ElementNode(type: .p, attributes: [], children: [gutenpack, text])
        let rootNode = RootNode(children: [paragraph])
        
        processor.process(rootNode)
        XCTAssertTrue(rootNode.rawText().contains("This text will be lost"))
    }
    
    /// There was an issue with Gutenberg posts losing edits.  This automated test makes sure the issues we found don't regress.
    ///
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/1052
    ///
    func testDataLossWhenProcessing2() {
        
        let paragraphBefore = ElementNode(type: .gutenblock, attributes: [], children: [TextNode(text: "a")])
        let paragraphAfter = ElementNode(type: .gutenblock, attributes: [], children: [TextNode(text: "b")])
        
        let commentNode = CommentNode(text: "wp:latestposts /")
        let gutenpackAttribute = encoder.selfClosingAttribute(for: commentNode)
        let gutenpack = ElementNode(type: .gutenpack, attributes: [gutenpackAttribute], children: [])
        
        let paragraph = ElementNode(type: .p, attributes: [], children: [paragraphBefore, gutenpack, paragraphAfter])
        let rootNode = RootNode(children: [paragraph])
        
        processor.process(rootNode)
    }
}
