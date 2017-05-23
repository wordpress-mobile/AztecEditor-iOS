import XCTest
@testable import AztecExample

class HTMLProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testProcessorOfVideoPressCode() {
        let processor = HTMLProcessor(tag:"video", replacer:{ (videoElement) in
            guard let videoPressID = videoElement.attributes.named["data-wpvideopress"] else {
                return nil
            }
            var html = "[wpvideo \(videoPressID) "

            for attribute in videoElement.attributes.named {
                if attribute.key == "src" || attribute.key == "data-wpvideopress" {
                    continue
                }
                html += "\(attribute.key)=\"\(attribute.value)\" "
            }
            for attribute in videoElement.attributes.unamed {
                html += "\(attribute) "
            }
            html += "/]"
            return html
        })
        let sampleText = "<video src=\"videopress://OcobLTqC\" width=640 height=400 data-wpvideopress=\"OcobLTqC\" />"
        let parsedText = processor.process(text: sampleText)
        XCTAssertEqual(parsedText, "[wpvideo OcobLTqC height=\"400\" width=\"640\" /]")
    }
    
}
