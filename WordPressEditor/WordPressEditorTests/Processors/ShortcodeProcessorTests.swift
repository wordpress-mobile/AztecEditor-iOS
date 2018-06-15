import Aztec
import XCTest
@testable import WordPressEditor

// MARK: - ShortcodeProcessorTests
//
class ShortcodeProcessorTests: XCTestCase {

    func testParserOfVideoPressCode() {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        let shortCodeParser = ShortcodeProcessor(tag:"wpvideo", replacer:{ (shortcode) in
            var html = "<video "

            if let src = shortcode.attributes.first(where: { $0.value == .nil }) {
                html += shortcodeAttributeSerializer.serialize(key: "src", value: "videopress://\(src.key)") + " "
                html += shortcodeAttributeSerializer.serialize(key: "data-wpvideopress", value: src.key) + " "
            }
            
            if let width = shortcode.attributes["w"] {
                html += shortcodeAttributeSerializer.serialize(key: "width", value: width.value) + " "
            }
            
            if let height = shortcode.attributes["h"] {
                html += shortcodeAttributeSerializer.serialize(key: "height", value: height.value) + " "
            }
            
            html += "/>"
            
            return html
        })
        
        let sampleText = "[wpvideo OcobLTqC w=640 h=400 autoplay=true html5only=true] Some Text"
        let parsedText = shortCodeParser.process(sampleText)
        let expected = "<video src=\"videopress://OcobLTqC\" data-wpvideopress=\"OcobLTqC\" width=\"640\" height=\"400\" /> Some Text"
        
        XCTAssertEqual(parsedText, expected)
    }

    func testParserOfWordPressVideoCode() {
        let shortcodeAttributeSerializer = ShortcodeAttributeSerializer()
        
        let shortCodeParser = ShortcodeProcessor(tag:"video", replacer: { (shortcode) in
            var html = "<video "
            
            if let src = shortcode.attributes["src"] {
                html += shortcodeAttributeSerializer.serialize(src) + " "
            }
            
            html += "/>"
            
            return html
        })
        
        let sampleText = "[video src=\"video-source.mp4\"]"
        let parsedText = shortCodeParser.process(sampleText)
        
        XCTAssertEqual(parsedText, "<video src=\"video-source.mp4\" />")
    }
}
