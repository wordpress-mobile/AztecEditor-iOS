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
            
            var html = "[wpvideo \(videoPressID) "
            
            for attribute in videoElement.attributes {
                guard !["src", "data-wpvideopress"].contains(attribute.key) else {
                    continue
                }
                
                html += shortcodeAttributeSerializer.serialize(attribute)
            }
            
            html += "/]"
            
            return html
        })
        let sampleText = "<video src=\"videopress://OcobLTqC\" width=640 height=400 data-wpvideopress=\"OcobLTqC\" />"
        let parsedText = processor.process(sampleText)
        XCTAssertEqual(parsedText, "[wpvideo OcobLTqC height=\"400\" width=\"640\" /]")
    }
    
}
