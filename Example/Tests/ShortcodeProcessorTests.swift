import XCTest
@testable import AztecExample

class ShortcodeProcessorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testParserOfVideoPressCode() {
        let shortCodeParser = ShortcodeProcessor(tag:"wpvideo", replacer:{ (shortcode) in
            var html = "<video "
            if let src = shortcode.attributes.unamed.first {
                html += "src=\"videopress://\(src)\" "
                html += "data-wpvideopress=\"\(src)\" "
            }
            if let width = shortcode.attributes.named["w"] {
                html += "width=\(width) "
            }
            if let height = shortcode.attributes.named["h"] {
                html += "height=\(height) "
            }
            html += "/>"
            return html
        })
        let sampleText = "[wpvideo OcobLTqC w=640 h=400 autoplay=true html5only=true] Some Text"
        let parsedText = shortCodeParser.process(text: sampleText)
        XCTAssertEqual(parsedText, "<video src=\"videopress://OcobLTqC\" data-wpvideopress=\"OcobLTqC\" width=640 height=400 /> Some Text")
    }

    func testParserOfWordPressVideoCode() {
        let shortCodeParser = ShortcodeProcessor(tag:"video", replacer: { (shortcode) in
            var html = "<video "
            if let src = shortcode.attributes.named["src"] {
                html += "src=\"\(src)\" "
            }
            html += "/>"
            return html
        })
        let sampleText = "[video src=\"video-source.mp4\"]"
        let parsedText = shortCodeParser.process(text: sampleText)
        XCTAssertEqual(parsedText, "<video src=\"video-source.mp4\" />")
    }
    
}
