import Foundation
import XCTest
@testable import Aztec


class TextStorageTests: XCTestCase
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
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 10)
        ]
        let storage = TextStorage()
        storage.append(NSAttributedString(string: "foo"))
        storage.append(NSAttributedString(string: "bar", attributes: attributes))
        storage.append(NSAttributedString(string: "baz"))

        // Foo
        XCTAssert(!storage.fontTrait(.traitBold, existsAtIndex: 0))
        XCTAssert(!storage.fontTrait(.traitBold, existsAtIndex: 2))
        // Bar
        XCTAssert(storage.fontTrait(.traitBold, existsAtIndex: 3))
        XCTAssert(storage.fontTrait(.traitBold, existsAtIndex: 4))
        XCTAssert(storage.fontTrait(.traitBold, existsAtIndex: 5))
        // Baz
        XCTAssert(!storage.fontTrait(.traitBold, existsAtIndex: 6))
        XCTAssert(!storage.fontTrait(.traitBold, existsAtIndex: 8))
    }

    func testFontTraitSpansRange() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 10)
        ]
        let storage = TextStorage()
        storage.append(NSAttributedString(string: "foo"))
        storage.append(NSAttributedString(string: "bar", attributes: attributes))
        storage.append(NSAttributedString(string: "baz"))

        XCTAssert(storage.fontTrait(.traitBold, spansRange: NSRange(location: 3, length: 3)))
        XCTAssert(!storage.fontTrait(.traitBold, spansRange: NSRange(location: 0, length: 9)))

    }

    func testToggleTraitInRange() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 10)
        ]
        let storage = TextStorage()
        storage.append(NSAttributedString(string: "foo"))
        storage.append(NSAttributedString(string: "bar", attributes: attributes))
        storage.append(NSAttributedString(string: "baz"))

        let range = NSRange(location: 3, length: 3)

        // Confirm the trait exists
        XCTAssert(storage.fontTrait(.traitBold, spansRange: range))

        // Toggle it.
        storage.toggle(.traitBold, inRange: range)

        // Confirm the trait does not exist.
        XCTAssert(!storage.fontTrait(.traitBold, spansRange: range))

        // Toggle it again.
        storage.toggle(.traitBold, inRange: range)

        // Confirm the trait was restored
        XCTAssert(storage.fontTrait(.traitBold, spansRange: range))
    }

    func testDelegateCallbackWhenAttachmentRemoved() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let attachment = storage.insertImage(sourceURL: URL(string:"test://")!, atPosition: 0, placeHolderImage: UIImage())

        storage.replaceCharacters(in: NSRange(location: 0, length: 1) , with: NSAttributedString(string:""))

        XCTAssertTrue(mockDelegate.deletedAttachmendIDCalledWithString == attachment.identifier)
    }

    class MockAttachmentsDelegate: TextStorageAttachmentsDelegate {

        var deletedAttachmendIDCalledWithString: String?

        func storage(_ storage: TextStorage, deletedAttachmentWithID attachmentID: String) {
            deletedAttachmendIDCalledWithString = attachmentID
        }

        func storage(_ storage: TextStorage, urlForImage image: UIImage) -> URL {
            return URL(string:"test://")!
        }

        func storage(_ storage: TextStorage, missingImageForAttachment: TextAttachment) -> UIImage {
            return UIImage()
        }

        func storage(_ storage: TextStorage, attachment: TextAttachment, imageForURL url: URL, onSuccess success: @escaping (UIImage) -> (), onFailure failure: @escaping () -> ()) -> UIImage {
            return UIImage()
        }
    }
}
