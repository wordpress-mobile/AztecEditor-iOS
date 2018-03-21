import Foundation
import XCTest
@testable import Aztec

class ParagraphStyleTests: XCTestCase {
    
    func testThatIsEqualSwizzlingWorked() {
        let nsParagraphStyle = NSParagraphStyle()
        let ourParagraphStyle = ParagraphStyle()
        
        // First we make sure we haven't affected the base implementation
        XCTAssert(nsParagraphStyle.swizzledIsEqual(ourParagraphStyle))
        
        XCTAssertEqual(nsParagraphStyle.isEqual(ourParagraphStyle), false)
        XCTAssertEqual(ourParagraphStyle.isEqual(nsParagraphStyle), false)
    }
}
