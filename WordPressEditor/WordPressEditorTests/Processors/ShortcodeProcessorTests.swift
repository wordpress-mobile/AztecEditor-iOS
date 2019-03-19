import Aztec
import XCTest
@testable import WordPressEditor

// MARK: - ShortcodeProcessorTests
//
class ShortcodeProcessorTests: XCTestCase {

    func testParserOfVideoPressCode() {        
        
        let shortCodeParser = VideoShortcodeProcessor.videoPressPreProcessor
        
        let sampleText = "[wpvideo OcobLTqC w=640 h=400 autoplay=true html5only=true] Some Text"
        let parsedText = shortCodeParser.process(sampleText)
        let expected = "<video src=\"videopress://OcobLTqC\" data-wpvideopress=\"OcobLTqC\" width=\"640\" height=\"400\" /> Some Text"
        
        XCTAssertEqual(parsedText, expected)
    }

    func testParserOfWordPressVideoCode() {
        
        let shortCodeParser = VideoShortcodeProcessor.wordPressVideoPreProcessor
        
        let sampleText = "[video src=\"video-source.mp4\"]"
        let parsedText = shortCodeParser.process(sampleText)
        
        XCTAssertEqual(parsedText, "<video src=\"video-source.mp4\" data-wpvideoshortcode=\"true\" />")
    }

    func testOutputParserOfVideoPressCode() {

        let shortCodeParser = VideoShortcodeProcessor.videoPressPostProcessor

        let sampleText = "<video src=\"videopress://OcobLTqC\" data-wpvideopress=\"OcobLTqC\" width=\"640\" height=\"400\" /> Some Text"
        let parsedText = shortCodeParser.process(sampleText)
        let expected = "[wpvideo OcobLTqC w=\"640\" h=\"400\" ] Some Text"

        XCTAssertEqual(parsedText, expected)
    }

    func testOutputParserOfWordPressVideoCode() {

        let shortCodeParser = VideoShortcodeProcessor.wordPressVideoPostProcessor

        let sampleText = "<video src=\"video-source.mp4\" data-wpvideoshortcode=\"true\" />"
        let parsedText = shortCodeParser.process(sampleText)
        let expected = "[video src=\"video-source.mp4\" ]"
        XCTAssertEqual(parsedText, expected)
    }
}
