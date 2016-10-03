import XCTest
@testable import Aztec

class NSRange_ComparisonTests: XCTestCase {
    
    /// Tests that `intersect(withRange:)` works.
    ///
    /// Set up:
    /// - Receiver range: (loc: 0, len: 10)
    /// - Target range: (loc: 0, len: 10)
    ///
    /// Expected result:
    /// - (loc: 0, len: 10)
    ///
    func testIntersectWithRange() {
        let receiver = NSRange(location: 0, length: 10)
        let target = NSRange(location: 0, length: 10)
        
        guard let result = receiver.intersect(withRange: target) else {
            XCTFail("Expected a non nil result.")
            return
        }
        
        XCTAssertEqual(result.location, 0)
        XCTAssertEqual(result.length, 10)
    }
    
    /// Tests that `intersect(withRange:)` works.
    ///
    /// Set up:
    /// - Receiver range: (loc: 0, len: 5)
    /// - Target range: (loc: 5, len: 5)
    ///
    /// Expected result:
    /// - (loc: 5, len: 0)
    ///
    func testIntersectWithRange2() {
        let receiver = NSRange(location: 0, length: 5)
        let target = NSRange(location: 5, length: 5)
        
        guard let result = receiver.intersect(withRange: target) else {
            XCTFail("Expected a non nil result.")
            return
        }
        
        XCTAssertEqual(result.location, 5)
        XCTAssertEqual(result.length, 0)
    }
    
    /// Tests that `intersect(withRange:)` works.
    ///
    /// Set up:
    /// - Receiver range: (loc: 0, len: 5)
    /// - Target range: (loc: 2, len: 5)
    ///
    /// Expected result:
    /// - (loc: 2, len: 3)
    ///
    func testIntersectWithRange3() {
        let receiver = NSRange(location: 0, length: 5)
        let target = NSRange(location: 2, length: 5)
        
        guard let result = receiver.intersect(withRange: target) else {
            XCTFail("Expected a non nil result.")
            return
        }
        
        XCTAssertEqual(result.location, 2)
        XCTAssertEqual(result.length, 3)
    }
    
    /// Tests that `intersect(withRange:)` works.
    ///
    /// Set up:
    /// - Receiver range: (loc: 3, len: 5)
    /// - Target range: (loc: 0, len: 5)
    ///
    /// Expected result:
    /// - (loc: 3, len: 2)
    ///
    func testIntersectWithRange4() {
        let receiver = NSRange(location: 3, length: 5)
        let target = NSRange(location: 0, length: 5)
        
        guard let result = receiver.intersect(withRange: target) else {
            XCTFail("Expected a non nil result.")
            return
        }
        
        XCTAssertEqual(result.location, 3)
        XCTAssertEqual(result.length, 2)
    }
    
    
    /// Tests that `intersect(withRange:)` works.
    ///
    /// Set up:
    /// - Receiver range: (loc: 0, len: 5)
    /// - Target range: (loc: 1, len: 2)
    ///
    /// Expected result:
    /// - (loc: 1, len: 2)
    ///
    func testIntersectWithRange5() {
        let receiver = NSRange(location: 0, length: 5)
        let target = NSRange(location: 1, length: 2)
        
        guard let result = receiver.intersect(withRange: target) else {
            XCTFail("Expected a non nil result.")
            return
        }
        
        XCTAssertEqual(result.location, 1)
        XCTAssertEqual(result.length, 2)
    }
    
    /// Tests that `intersect(withRange:)` works.
    ///
    /// Set up:
    /// - Receiver range: (loc: 1, len: 3)
    /// - Target range: (loc: 0, len: 5)
    ///
    /// Expected result:
    /// - (loc: 1, len: 3)
    ///
    func testIntersectWithRange6() {
        let receiver = NSRange(location: 1, length: 3)
        let target = NSRange(location: 0, length: 5)
        
        guard let result = receiver.intersect(withRange: target) else {
            XCTFail("Expected a non nil result.")
            return
        }
        
        XCTAssertEqual(result.location, 1)
        XCTAssertEqual(result.length, 3)
    }
    
    /// Tests that `intersect(withRange:)` works.
    ///
    /// Set up:
    /// - Receiver range: (loc: 0, len: 3)
    /// - Target range: (loc: 5, len: 5)
    ///
    /// Expected result:
    /// - `nil`
    ///
    func testIntersectWithRange7() {
        let receiver = NSRange(location: 0, length: 3)
        let target = NSRange(location: 5, length: 5)
        
        let result = receiver.intersect(withRange: target)
        
        XCTAssertNil(result)
    }
}
