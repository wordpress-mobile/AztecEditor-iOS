import XCTest
@testable import AztecExample


// MARK: - CaptionShortcodePreProcessorTests
//
class CaptionShortcodePreProcessorTests: XCTestCase {

    let processor = CaptionShortcodePreProcessor()


    /// Verifies that a Caption Shortcode wrapping an Image + Text is properly processed.
    ///
    func testCaptionShortcodeIsProperlyConvertedIntoFigureTag() {
        let input = "[caption]<img src=\".\">Text[/caption]"
        let expected = "<figure><img src=\".\"><figcaption>Text</figcaption></figure>"

        XCTAssertEqual(processor.process(input), expected)
    }


    /// Verifies that a caption shortcode wrapping [Image + Text + Multiple Line Breaks] is properly processed.
    ///
    func testCaptionShortcodeIsProperlyConvertedIntoFigureTagPreservingNestedTags() {
        let input = "[caption]<img src=\".\"><b>Text</b><br><br><br>[/caption]"
        let expected = "<figure><img src=\".\"><figcaption><b>Text</b><br><br><br></figcaption></figure>"

        XCTAssertEqual(processor.process(input), expected)
    }


    /// Verifies that the caption shortcode's attributes are transferred over the Figure Tag.
    ///
    func testCaptionShortcodeAttributesAreProperlyPassedOntoTheFigureTag() {
        let input = "[caption id=\"attachment_6\" align=\"alignleft\" width=\"300\" class=\"span data-mce-type=\"]" +
                        "<img src=\".\">Text" +
                    "[/caption]"

        let expected = "<figure align=\"alignleft\" class=\"span data-mce-type=\" id=\"attachment_6\" width=\"300\">" +
                            "<img src=\".\"><figcaption>Text</figcaption>" +
                        "</figure>"

        XCTAssertEqual(processor.process(input), expected)
    }


    /// Verifies that a caption shortcode with no text doesn't get processed.
    ///
    func testCaptionShortcodeDoesNotGetProcessedIfThereIsNoTextContent() {
        let input = "[caption]<img src=\".\">[/caption]"

        XCTAssertEqual(processor.process(input), input)
    }


    /// Verifies that a caption shortcode with no image doesn't get processed.
    ///
    func testCaptionShortcodeDoesNotGetProcessedIfThereIsNoImage() {
        let input = "[caption]Text[/caption]"

        XCTAssertEqual(processor.process(input), input)
    }
}
