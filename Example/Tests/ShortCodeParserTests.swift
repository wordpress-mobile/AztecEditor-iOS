import XCTest
@testable import AztecExample

class ShortCodeParserTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testParserOfVideoPressCode() {
        let shortCodeParser = ShortcodeProcessor(tag:"wpvideo", replacer:{ (shortcode) in
            var html = "<video "
            if let src = shortcode.attributes.unamedAttributes.first {
                html += "src=\"videopress://\(src)\" "
            }
            if let width = shortcode.attributes.namedAttributes["w"] {
                html += "width=\(width) "
            }
            if let height = shortcode.attributes.namedAttributes["h"] {
                html += "height=\(height) "
            }
            html += "\\>"
            return html
        })
        let sampleText = "[wpvideo OcobLTqC w=640 h=400 autoplay=true html5only=true] Some Text [wpvideo OcobLTqC w=640 h=400 autoplay=true html5only=true]"
        let parsedText = shortCodeParser.process(text: sampleText)
        XCTAssertEqual(parsedText, "<video src=\"videopress://OcobLTqC\" width=640 height=400 \\> Some Text <video src=\"videopress://OcobLTqC\" width=640 height=400 \\>")
    }

    func testParserOfWordPressVideoCode() {
        let shortCodeParser = ShortcodeProcessor(tag:"video", replacer: { (shortcode) in
            var html = "<video "
            if let src = shortcode.attributes.namedAttributes["src"] {
                html += "src=\"\(src)\" "
            }
            html += "\\>"
            return html
        })
        let sampleText = "[video src=\"video-source.mp4\"]"
        let parsedText = shortCodeParser.process(text: sampleText)
        XCTAssertEqual(parsedText, "<video src=\"video-source.mp4\" \\>")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
