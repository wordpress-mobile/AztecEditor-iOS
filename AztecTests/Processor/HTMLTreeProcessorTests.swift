import XCTest
@testable import Aztec

class HTMLTreeProcessorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Test Support Logic
    
    private let firstProcessorOutputText = "Testing the processor!"
    private let secondProcessorOutputText = "\nTesting some more!"
    
    private class FirstTestTreeProcessor: HTMLTreeProcessor {
        func process(_ rootNode: RootNode) {
            let textNode = TextNode(text: "Testing the processor!")
            
            rootNode.children = [textNode]
        }
    }
    
    private class SecondTestTreeProcessor: HTMLTreeProcessor {
        func process(_ rootNode: RootNode) {
            let brNode = ElementNode(type: .br)
            let textNode = TextNode(text: "Testing some more!")

            rootNode.children.append(contentsOf: [brNode, textNode])
        }
    }
    
    // MARK: - HTMLTreeProcessorPipeline
    
    func testTreeProcessorPipelineWorks() {
        let originalContents = TextNode(text: "Original contents!")
        let rootNode = RootNode(children: [originalContents])
        
        let firstTreeProcessor = FirstTestTreeProcessor()
        let secondTreeProcessor = SecondTestTreeProcessor()
        let pipelineProcessor = HTMLTreeProcessorPipeline(processors: [firstTreeProcessor, secondTreeProcessor])
        
        pipelineProcessor.process(rootNode)
        
        XCTAssertEqual(rootNode.children.count, 3)
        XCTAssertEqual(rootNode.rawText(), firstProcessorOutputText + secondProcessorOutputText)
    }
    
}
