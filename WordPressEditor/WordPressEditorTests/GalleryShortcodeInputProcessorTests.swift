import XCTest
@testable import WordPressEditor

class GalleryShortcodeInputProcessorTests: XCTestCase {
    
    let processor = GalleryShortcodeInputProcessor()
    
    /// Verifies that a Caption Shortcode wrapping an Image + Text is properly processed.
    ///
    func testGalleryShortcodeWithOnlyColumns() {
        let input = "[gallery columns=\"4\"]"
        let expected = "<gallery columns=\"4\">"
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
    }
}
