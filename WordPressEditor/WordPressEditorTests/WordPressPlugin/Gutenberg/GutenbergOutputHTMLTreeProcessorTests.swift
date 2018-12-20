import Aztec
import XCTest
@testable import WordPressEditor

class GutenbergOutputHTMLTreeProcessorTests: XCTestCase {
    
    let parser = HTMLParser()
    let inputProcessor = GutenbergInputHTMLTreeProcessor()
    let outputProcessor = GutenbergOutputHTMLTreeProcessor()
    let encoder = GutenbergAttributeEncoder()
    
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
        
        outputProcessor.process(rootNode)
        XCTAssertTrue(rootNode.rawText().contains("This text will be lost"))
    }
    
    /// There was an issue with Gutenberg posts crashing GutenbergOutputHTMLTreeProcessor.
    ///
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/1111
    ///
    func testNoCrashWhenTestingTwoGutenpacksInSequence() {
        
        let commentText = "wp:latestposts /"
        let commentNode = CommentNode(text: commentText)
        let gutenpackAttribute = encoder.selfClosingAttribute(for: commentNode)
        let gutenpack = ElementNode(type: .gutenpack, attributes: [gutenpackAttribute], children: [])
        
        let commentText2 = "wp:latestposts /"
        let commentNode2 = CommentNode(text: commentText2)
        let gutenpackAttribute2 = encoder.selfClosingAttribute(for: commentNode2)
        let gutenpack2 = ElementNode(type: .gutenpack, attributes: [gutenpackAttribute2], children: [])
        
        let paragraph = ElementNode(type: .p, attributes: [], children: [gutenpack, gutenpack2])
        let rootNode = RootNode(children: [paragraph])
        
        outputProcessor.process(rootNode)
        
        let childComments = rootNode.children.compactMap { node -> CommentNode? in
            guard let commentNode = node as? CommentNode else {
                return nil
            }
            
            return commentNode
        }
        
        XCTAssertEqual(childComments.count, 2)
        XCTAssertEqual(childComments[0].comment, commentText)
        XCTAssertEqual(childComments[1].comment, commentText2)
    }
}
