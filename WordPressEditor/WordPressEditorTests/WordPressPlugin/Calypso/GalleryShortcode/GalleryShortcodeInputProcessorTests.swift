import XCTest
@testable import WordPressEditor

class GalleryShortcodeInputProcessorTests: XCTestCase {
    
    let processor = GalleryShortcodeInputProcessor()
    
    /// Verifies that a Caption Shortcode with a columns attribute is properly pre-processed.
    ///
    func testGalleryShortcodeWithOnlyColumns() {
        let input = "[gallery columns=\"4\"]"
        let expected = "<gallery columns=\"4\" />"
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
    }
    
    /// Verifies that a Caption Shortcode with an IDs attribute is properly pre-processed.
    ///
    func testGalleryShortcodeWithOnlyIDs() {
        let input = "[gallery ids=\"4,10,22,11\"]"
        let expected = "<gallery ids=\"4,10,22,11\" />"
        
        let output = processor.process(input)
        
        XCTAssertEqual(output, expected)
    }
}
