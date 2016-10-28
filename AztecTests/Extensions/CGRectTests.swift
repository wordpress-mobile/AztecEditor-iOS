import Foundation
import XCTest
@testable import Aztec

class CGRectTests: XCTestCase {

    // MARK: - Resize (Grow)

    func testResizeGrowWithDefaultParameters() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 200, height: 200)
        let expected = CGRect(x: 100, y: 100, width: 200, height: 200)
        let resized = original.resize(to: size)

        XCTAssertEqual(resized, expected)
    }

    func testResizeGrowWithCenterAnchor() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 200, height: 200)
        let expected = CGRect(x: 50, y: 100, width: 200, height: 200)
        let resized = original.resize(to: size, horizontalAnchor: .center)

        XCTAssertEqual(resized, expected)
    }

    func testResizeGrowWithRightAnchor() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 200, height: 200)
        let expected = CGRect(x: 0, y: 100, width: 200, height: 200)
        let resized = original.resize(to: size, horizontalAnchor: .right)

        XCTAssertEqual(resized, expected)
    }

    func testResizeGrowWithMiddleAnchor() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 200, height: 200)
        let expected = CGRect(x: 100, y: 50, width: 200, height: 200)
        let resized = original.resize(to: size, verticalAnchor: .middle)

        XCTAssertEqual(resized, expected)
    }

    func testResizeGrowWithBottomAnchor() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 200, height: 200)
        let expected = CGRect(x: 100, y: 0, width: 200, height: 200)
        let resized = original.resize(to: size, verticalAnchor: .bottom)

        XCTAssertEqual(resized, expected)
    }
    
    func testResizeGrowCentered() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 200, height: 200)
        let expected = CGRect(x: 50, y: 50, width: 200, height: 200)
        let resized = original.resize(to: size, horizontalAnchor: .center, verticalAnchor: .middle)

        XCTAssertEqual(resized, expected)
    }

    // MARK: - Resize (Shrink)

    func testResizeShrinkWithDefaultParameters() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 50, height: 50)
        let expected = CGRect(x: 100, y: 100, width: 50, height: 50)
        let resized = original.resize(to: size)

        XCTAssertEqual(resized, expected)
    }

    func testResizeShrinkWithCenterAnchor() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 50, height: 50)
        let expected = CGRect(x: 125, y: 100, width: 50, height: 50)
        let resized = original.resize(to: size, horizontalAnchor: .center)

        XCTAssertEqual(resized, expected)
    }

    func testResizeShrinkWithRightAnchor() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 50, height: 50)
        let expected = CGRect(x: 150, y: 100, width: 50, height: 50)
        let resized = original.resize(to: size, horizontalAnchor: .right)

        XCTAssertEqual(resized, expected)
    }

    func testResizeShrinkWithMiddleAnchor() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 50, height: 50)
        let expected = CGRect(x: 100, y: 125, width: 50, height: 50)
        let resized = original.resize(to: size, verticalAnchor: .middle)

        XCTAssertEqual(resized, expected)
    }

    func testResizeShrinkWithBottomAnchor() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 50, height: 50)
        let expected = CGRect(x: 100, y: 150, width: 50, height: 50)
        let resized = original.resize(to: size, verticalAnchor: .bottom)

        XCTAssertEqual(resized, expected)
    }

    func testResizeShrinkCentered() {
        let original = CGRect(x: 100, y: 100, width: 100, height: 100)
        let size = CGSize(width: 50, height: 50)
        let expected = CGRect(x: 125, y: 125, width: 50, height: 50)
        let resized = original.resize(to: size, horizontalAnchor: .center, verticalAnchor: .middle)

        XCTAssertEqual(resized, expected)
    }
    

}
