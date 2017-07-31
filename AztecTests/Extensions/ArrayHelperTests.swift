import XCTest
@testable import Aztec


// MARK: - Array Helper Tests
//
class ArrayHelperTests: XCTestCase {

    /// Verifies that the `lastIndex` helper effectively returns the position of the last satisfying
    /// element within the collection.
    ///
    func testLastIndexEffectivelyReturnsTheLastSatisfyingElementIndex() {
        let collection = [9,8,7,6,5,4,3,2,1,9,0,9,0]

        guard let index = collection.lastIndex(where: { $0 == 9 }) else {
            XCTFail()
            return
        }

        XCTAssert(index == (collection.count - 2))
    }

    /// Verifies that the `lastIndex` helper effectively returns nil whenever there is just no single
    /// element within the collection that would satisfy the specified condition.
    ///
    func testLastIndexEffectivelyReturnsNilWheneverThereIsNoSatisfyingElement() {
        let collection = [9,8,7,6,5,4,3,2,1,9,0,9,0]

        guard let _ = collection.lastIndex(where: { $0 == 15 }) else {
            return
        }

        XCTFail()
    }
}
