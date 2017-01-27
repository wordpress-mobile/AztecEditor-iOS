import XCTest
@testable import Aztec

class NSAttributedStringAttributeRangesTests: XCTestCase {
    
    /// Tests that `rangeOfTextList` works.
    ///
    /// Set up:
    /// - Sample NSAttributedString, with no TextList
    ///
    /// Expected result:
    /// - nil for the whole String Length
    ///
    func testMap() {
        for index in (0 ... samplePlainString.length) {
            XCTAssertNil(samplePlainString.rangeOfTextList(atIndex: index))
        }
    }
}
