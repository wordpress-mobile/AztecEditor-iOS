import Foundation
import XCTest
import Aztec


class AztecTextStorageTests: XCTestCase
{

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - Test Traits

    func testFontTraitExistsAtIndex() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(10)
        ]
        let storage = AztecTextStorage()
        storage.appendAttributedString(NSAttributedString(string: "foo"))
        storage.appendAttributedString(NSAttributedString(string: "bar", attributes: attributes))
        storage.appendAttributedString(NSAttributedString(string: "baz"))

        // Foo
        XCTAssert(!storage.fontTrait(.TraitBold, existsAtIndex: 0))
        XCTAssert(!storage.fontTrait(.TraitBold, existsAtIndex: 2))
        // Bar
        XCTAssert(storage.fontTrait(.TraitBold, existsAtIndex: 3))
        XCTAssert(storage.fontTrait(.TraitBold, existsAtIndex: 4))
        XCTAssert(storage.fontTrait(.TraitBold, existsAtIndex: 5))
        // Baz
        XCTAssert(!storage.fontTrait(.TraitBold, existsAtIndex: 6))
        XCTAssert(!storage.fontTrait(.TraitBold, existsAtIndex: 8))
    }
    
    func testFontTraitSpansRange() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(10)
        ]
        let storage = AztecTextStorage()
        storage.appendAttributedString(NSAttributedString(string: "foo"))
        storage.appendAttributedString(NSAttributedString(string: "bar", attributes: attributes))
        storage.appendAttributedString(NSAttributedString(string: "baz"))

        XCTAssert(storage.fontTrait(.TraitBold, spansRange: NSRange(location: 3, length: 3)))
        XCTAssert(!storage.fontTrait(.TraitBold, spansRange: NSRange(location: 0, length: 9)))

    }

    func testToggleTraitInRange() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(10)
        ]
        let storage = AztecTextStorage()
        storage.appendAttributedString(NSAttributedString(string: "foo"))
        storage.appendAttributedString(NSAttributedString(string: "bar", attributes: attributes))
        storage.appendAttributedString(NSAttributedString(string: "baz"))

        let range = NSRange(location: 3, length: 3)

        // Confirm the trait exists
        XCTAssert(storage.fontTrait(.TraitBold, spansRange: range))

        // Toggle it.
        storage.toggleFontTrait(.TraitBold, range: range)

        // Confirm the trait does not exist.
        XCTAssert(!storage.fontTrait(.TraitBold, spansRange: range))

        // Toggle it again.
        storage.toggleFontTrait(.TraitBold, range: range)

        // Confirm the trait was restored
        XCTAssert(storage.fontTrait(.TraitBold, spansRange: range))
    }

}
