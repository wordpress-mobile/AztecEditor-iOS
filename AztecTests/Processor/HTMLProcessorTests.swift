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
        
        let processor = HTMLProcessor(for: "video", replacer:{ (videoElement) in
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
    
    func testProcessorOfNestedDivs() {
        let innerContent = """
        <div class="wp-block-cover__inner-container">
        <!-- wp:paragraph {"align":"center","placeholder":"Write title…"} -->
        <p class="has-text-align-center"></p>
        <!-- /wp:paragraph -->
        </div>
        """
        
        let sampleText = """
        <div class="wp-block-cover has-background-dim" style="background-image:url(file:///usr/tmp/-1175513456.jpg)">\(innerContent)</div>
        """
        
        let processor = HTMLProcessor(for: "div", replacer:{ (divElement) in
            XCTAssertEqual(divElement.tag, "div")
            XCTAssertEqual(divElement.type, HTMLElement.TagType.closed)
            XCTAssertEqual(divElement.content, innerContent)
            return ""
        })
        
        let _ = processor.process(sampleText)
    }
    
}
