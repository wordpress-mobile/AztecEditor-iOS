import XCTest
@testable import Aztec

class HTMLProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testProcessorOfVideoPressCode() {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        let processor = HTMLProcessor(tag:"video", replacer:{ (videoElement) in
            guard let videoPressID = videoElement.attributes["data-wpvideopress"] else {
                return nil
            }
            
            let attributes = videoElement.attributes.filter() { !["src", "data-wpvideopress"].contains($0.key) }
            
            var html = "[wpvideo "
            html += shortcodeAttributeSerializer.serialize(videoPressID.value) + " "
            html += shortcodeAttributeSerializer.serialize(attributes)
            html += "/]"
            
            return html
        })
        
        let sampleText = "<video src=\"videopress://OcobLTqC\" width=640 height=400 data-wpvideopress=\"OcobLTqC\" />"
        let parsedText = processor.process(sampleText)
        
        XCTAssertEqual(parsedText, "[wpvideo OcobLTqC width=\"640\" height=\"400\"/]")
    }
    
}
