import Foundation
import XCTest
@testable import Aztec

class ParagraphStyleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Unfortunately, the swizzling can only be activated by initializing ParagraphStyle.
        // In normal usage circumstances of Aztec this should not be a problem because Aztec would take care,
        // but in these tests we want to make sure the swizzling is activated.
        ParagraphStyle.initializeClass
    }
    
    func testThatIsEqualSwizzlingWorks() {
        let nsParagraphStyle = NSParagraphStyle()
        let ourParagraphStyle = ParagraphStyle()
        
        // First we make sure the swizzling is loaded.
        XCTAssert(nsParagraphStyle.swizzledIsEqual(ourParagraphStyle))
        
        XCTAssertEqual(nsParagraphStyle.isEqual(ourParagraphStyle), false)
        XCTAssertEqual(ourParagraphStyle.isEqual(nsParagraphStyle), false)
    }
    
    func testThatIsEqualSwizzlingWithNSMutableParagraphStyleAndNSParagraphStyleWorks() {
        let nsParagraphStyle = NSParagraphStyle()
        let mutableNSParagraphStyle = NSMutableParagraphStyle()
        
        // First we make sure the swizzling is loaded.
        XCTAssert(nsParagraphStyle.swizzledIsEqual(mutableNSParagraphStyle))
        
        XCTAssertEqual(nsParagraphStyle.isEqual(mutableNSParagraphStyle), true)
        XCTAssertEqual(mutableNSParagraphStyle.isEqual(nsParagraphStyle), true)
    }
}
