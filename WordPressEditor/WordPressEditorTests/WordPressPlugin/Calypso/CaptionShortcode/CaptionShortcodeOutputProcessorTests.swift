import XCTest
@testable import WordPressEditor

class CaptionShortcodeOutputProcessorTests: XCTestCase {

    let processor = CaptionShortcodeOutputProcessor()


    /// Verifies that a [Figure + Image + Figcaption] structure is properly mapped into a Caption Shortcode.
    ///
    func testFigureAndFigcaptionAreProperlyConvertedIntoCaptionShortcode() {
        let input = "<figure><img src=\".\"><figcaption>Text</figcaption></figure>"
        let expected = "[caption id=\"\"]<img src=\".\">Text[/caption]"

        XCTAssertEqual(processor.process(input), expected)
    }


    /// Verifies that a [Figure + Image + Figcaption (with nested tags)] structure is properly mapped into a Caption Shortcode.
    ///
    func testFigureTagWithNestedFigcaptionEntitiesIsProperlyConvertedBackIntoCaptionShortcode() {
        let input = "<figure><img src=\".\"><figcaption><b>Text</b><br><br><br></figcaption></figure>"
        let expected = "[caption id=\"\"]<img src=\".\"><b>Text</b><br><br><br>[/caption]"

        XCTAssertEqual(processor.process(input), expected)
    }


    /// Verifies that a Figure Tag (with parameters) gets properly converted into a Caption Shortcode.
    ///
    func testCaptionShortcodeAttributesAreProperlyPassedOntoTheFigureTag() {
        let input = "<figure id=\"attachment_6\" align=\"alignleft\" class=\"span data-mce-type=\" width=\"300\">" +
                        "<img src=\".\"><figcaption>Text</figcaption>" +
                    "</figure>"

        let expected = "[caption id=\"attachment_6\" align=\"alignleft\" class=\"span data-mce-type=\" width=\"300\"]" +
                            "<img src=\".\">Text" +
                        "[/caption]"

        XCTAssertEqual(processor.process(input), expected)
    }

    /// Verifies that a Img Tag (with parameters) gets properly converted into a Caption Shortcode.
    ///
    func testImgTagAttributesAreProperlyPassedOntoTheCaptionShortcode() {
        let input = "<figure>" +
            "<img src=\".\" class=\"alignleft wp-image-6\" width=\"300\"><figcaption>Text</figcaption>" +
        "</figure>"

        let expected = "[caption align=\"alignleft\" id=\"attachment_6\" width=\"300\"]" +
            "<img src=\".\" class=\"alignleft wp-image-6\" width=\"300\">Text" +
        "[/caption]"

        XCTAssertEqual(processor.process(input), expected)
    }

    /// Verifies that a figure with no figcaption tag does not get converted into a Caption Shortcode.
    ///
    func testFigureTagIsNotConvertedIntoCaptionShortcodeWheneverThereIsNoTextContent() {
        let input = "<figure><img src=\".\"></figure>"

        XCTAssertEqual(processor.process(input), input)
    }


    /// Verifies that a Figure Tag is not converted into a Caption Shortcode, whenever there is no image associated to it.
    ///
    func testFigureTagIsNotConvertedIntoCaptionShortcodeWheneverThereIsNoImage() {
        let input = "<figure><figcaption>Text</figcaption></figure>"

        XCTAssertEqual(processor.process(input), input)
    }
}
