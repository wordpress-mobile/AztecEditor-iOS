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

        func storage(_ storage: TextStorage, urlForAttachment attachment: TextAttachment) -> URL {
            return URL(string:"test://")!
        }

        func storage(_ storage: TextStorage, missingImageForAttachment: TextAttachment) -> UIImage {
            return UIImage()
        }

        func storage(_ storage: TextStorage, attachment: TextAttachment, imageForURL url: URL, onSuccess success: @escaping (UIImage) -> (), onFailure failure: @escaping () -> ()) -> UIImage {
            return UIImage()
        }
    }

    func testRemovalOfAttachment() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let attachment = storage.insertImage(sourceURL: URL(string:"test://")!, atPosition: 0, placeHolderImage: UIImage())

        storage.remove(attachmentID: attachment.identifier)

        XCTAssertTrue(mockDelegate.deletedAttachmendIDCalledWithString == attachment.identifier)
    }

    func testInsertImage() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let attachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 0, placeHolderImage: UIImage())
        let html = storage.getHTML()

        XCTAssertEqual(attachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(html, "<img src=\"https://wordpress.com\">")
    }

    func testUpdateImage() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate
        let url = URL(string: "https://wordpress.com")!
        let attachment = storage.insertImage(sourceURL: url, atPosition: 0, placeHolderImage: UIImage())
        storage.update(attachment: attachment, alignment: .left, size: .medium, url: url)
        let html = storage.getHTML()

        XCTAssertEqual(attachment.url, url)
        XCTAssertEqual(html, "<img src=\"https://wordpress.com\" class=\"alignleft size-medium\">")
    }

    func testBlockquoteToggle() {
        let storage = TextStorage()
        storage.append(NSAttributedString(string: "Apply a blockquote"))
        let blockquoteFormatter = BlockquoteFormatter()
        storage.toggle(formatter: blockquoteFormatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<blockquote>Apply a blockquote</blockquote>")

        storage.toggle(formatter:blockquoteFormatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "Apply a blockquote")
    }

    func testLinkInsert() {
        let storage = TextStorage()
        storage.append(NSAttributedString(string: "Apply a link"))
        let linkFormatter = LinkFormatter()
        linkFormatter.attributeValue = URL(string: "www.wordpress.com")!
        storage.toggle(formatter: linkFormatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<a href=\"www.wordpress.com\">Apply a link</a>")

        storage.toggle(formatter:linkFormatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "Apply a link")
    }

    func testHeaderToggle() {
        let storage = TextStorage()
        storage.append(NSAttributedString(string: "Apply a header"))
        let formatter = HeaderFormatter(headerLevel: .h1)
        storage.toggle(formatter: formatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<h1>Apply a header</h1>")

        storage.toggle(formatter:formatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "Apply a header")
    }


    /// This test check if the insertion of two images one after the other works correctly and to img tag are inserted
    ///
    func testInsertOneImageAfterTheOther() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let firstAttachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 0, placeHolderImage: UIImage())
        let secondAttachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.org")!, atPosition: 1, placeHolderImage: UIImage())
        let html = storage.getHTML()

        XCTAssertEqual(firstAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(secondAttachment.url, URL(string: "https://wordpress.org"))
        XCTAssertEqual(html, "<img src=\"https://wordpress.com\"><img src=\"https://wordpress.org\">")
    }

    /// This test check if the insertion of two images one after the other works correctly and to img tag are inserted
    ///
    func testInsertSameImageAfterTheOther() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let firstAttachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 0, placeHolderImage: UIImage())
        let secondAttachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 1, placeHolderImage: UIImage())
        let html = storage.getHTML()

        XCTAssertEqual(firstAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(secondAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(html, "<img src=\"https://wordpress.com\"><img src=\"https://wordpress.com\">")
    }

    /// This test verifies if the `removeTextAttachements` call effectively nukes all of the TextAttachments present
    /// in the storage.
    ///
    func testRemoveAllTextAttachmentsNukeTextAttachmentInstances() {
        // Mockup Storage
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let sample = NSMutableAttributedString(string: "Some string here")
        storage.append(sample)

        // New string with 10 attachments
        var identifiers = [String]()
        let count = 10

        for _ in 0 ..< count {
            let sourceURL = URL(string:"test://")!
            let attachment = storage.insertImage(sourceURL: sourceURL, atPosition: 0, placeHolderImage: UIImage())

            identifiers.append(attachment.identifier)
        }


        // Verify the attachments are there
        for identifier in identifiers {
            XCTAssertNotNil(storage.attachment(withId: identifier))
        }

        // Nuke
        storage.removeTextAttachments()

        // Verify the attachments are there
        for identifier in identifiers {
            XCTAssertNil(storage.attachment(withId: identifier))
        }
    }

    /// This test check if the insertion of an horizontal ruler works correctly and the hr tag is inserted
    ///
    func testInsertHorizontalRuler() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        storage.insertHorizontalRuler(at: NSRange.zero)
        let html = storage.getHTML()

        XCTAssertEqual(html, "<hr>")
    }

    /// This test check if the insertion of an horizontal ruler over an image attachment works correctly and the hr tag is inserted
    ///
    func testInsertHorizontalRulerOverImage() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let _ = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 0, placeHolderImage: UIImage())
        storage.insertHorizontalRuler(at: NSRange(location: 0, length:1))
        let html = storage.getHTML()

        XCTAssertEqual(html, "<hr>")
    }
}
