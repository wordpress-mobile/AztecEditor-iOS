import Foundation
import XCTest
@testable import Aztec


class TextStorageTests: XCTestCase {

    /// Test Storage
    ///
    var storage: TextStorage!

    /// Test Attachments Delegate
    ///
    var mockDelegate: MockAttachmentsDelegate!


    override func setUp() {
        super.setUp()

        mockDelegate = MockAttachmentsDelegate()
        storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate
    }


    // MARK: - Test Traits

    func testFontTraitExistsAtIndex() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 10)
        ]

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
        let mockDelegate = MockAttachmentsDelegate()
        let storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate
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
        let attachment = ImageAttachment(identifier: UUID().uuidString, url: URL(string:"test://")!)
        storage.replaceCharacters(in: NSRange(location:0, length: 0), with: NSAttributedString(attachment: attachment))

        storage.replaceCharacters(in: NSRange(location: 0, length: 1) , with: NSAttributedString(string:""))

        XCTAssertTrue(mockDelegate.deletedAttachmendIDCalledWithString == attachment.identifier)
    }

    class MockAttachmentsDelegate: TextStorageAttachmentsDelegate {

        var deletedAttachmendIDCalledWithString: String?

        func storage(_ storage: TextStorage, deletedAttachmentWith attachmentID: String) {
            deletedAttachmendIDCalledWithString = attachmentID
        }

        func storage(_ storage: TextStorage, urlFor imageAttachment: ImageAttachment) -> URL {
            return URL(string:"test://")!
        }

        func storage(_ storage: TextStorage, placeholderFor attachment: NSTextAttachment) -> UIImage {
            return UIImage()
        }

        func storage(_ storage: TextStorage, attachment: NSTextAttachment, imageFor url: URL, onSuccess success: @escaping (UIImage) -> (), onFailure failure: @escaping () -> ()) {
            // NO OP
        }

        func storage(_ storage: TextStorage, boundsFor attachment: NSTextAttachment, with lineFragment: CGRect) -> CGRect {
            return .zero
        }

        func storage(_ storage: TextStorage, imageFor attachment: NSTextAttachment, with size: CGSize) -> UIImage? {
            return UIImage()
        }
    }    

    func testInsertImage() {
        let attachment = ImageAttachment(identifier: UUID().uuidString, url: URL(string:"https://wordpress.com")!)
        storage.replaceCharacters(in: NSRange(location:0, length: 0), with: NSAttributedString(attachment: attachment))

        let html = storage.getHTML()

        XCTAssertEqual(attachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(html, "<p><img src=\"https://wordpress.com\"></p>")
    }

    /// Verifies that any edition performed on ImageAttachment attributes is properly serialized back during
    /// the HTML generation step.
    ///
    func testEditingImageAttachmentAfterItHasBeenInsertedCausesItsAttributesToProperlySerialize() {
        let url = URL(string: "https://wordpress.com")!
        let attachment = ImageAttachment(identifier: UUID().uuidString, url: url)

        storage.replaceCharacters(in: NSRange(location:0, length: 0), with: NSAttributedString(attachment: attachment))

        attachment.alignment = .left
        attachment.size = .medium

        let html = storage.getHTML()
        XCTAssertEqual(attachment.url, url)
        XCTAssertEqual(html, "<p><img src=\"https://wordpress.com\" class=\"alignleft size-medium\"></p>")
    }

    /// Verifies that any edition performed on HTMLttachment attributes is properly serialized back during
    /// the HTML generation step.
    ///
    func testUpdatingHtmlAttachmentEffectivelyUpdatesTheDom() {
        let initialHTML = "<unknown>html</unknown>"
        let updatedHTML = "<updated>NEW HTML</updated>"
        let finalHTML = "<p>\(updatedHTML)</p>"

        // Setup
        storage.setHTML(initialHTML, withDefaultFontDescriptor: UIFont.systemFont(ofSize: 10).fontDescriptor)

        // Find the Attachment
        var theAttachment: HTMLAttachment!
        storage.enumerateAttachmentsOfType(HTMLAttachment.self, range: nil) { (attachment, _, _) in
            theAttachment = attachment
        }

        // Update
        XCTAssertNotNil(theAttachment)
        theAttachment.rawHTML = updatedHTML

        // Verify
        XCTAssertEqual(storage.getHTML(), finalHTML)
    }

    func testBlockquoteToggle1() {
        storage.append(NSAttributedString(string: "Apply a blockquote"))

        let blockquoteFormatter = BlockquoteFormatter()
        storage.toggle(formatter: blockquoteFormatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<blockquote>Apply a blockquote</blockquote>")

        storage.toggle(formatter: blockquoteFormatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "<p>Apply a blockquote</p>")
    }

    func testBlockquoteToggle2() {
        storage.append(NSAttributedString(string: "Hello 🌎!\nApply a blockquote!"))
        let blockquoteFormatter = BlockquoteFormatter()

        let range = NSRange(location: 9, length: 19)
        let utf16Range = storage.string.utf16NSRange(from: range)

        storage.toggle(formatter: blockquoteFormatter, at: utf16Range)

        let html = storage.getHTML()

        XCTAssertEqual(html, "<p>Hello 🌎!</p><blockquote>Apply a blockquote!</blockquote>")
    }

    func testLinkInsert() {
        storage.append(NSAttributedString(string: "Apply a link"))
        let linkFormatter = LinkFormatter()
        linkFormatter.attributeValue = URL(string: "www.wordpress.com")!
        storage.toggle(formatter: linkFormatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<p><a href=\"www.wordpress.com\">Apply a link</a></p>")

        storage.toggle(formatter:linkFormatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "<p>Apply a link</p>")
    }

    func testHeaderToggle() {
        storage.append(NSAttributedString(string: "Apply a header"))
        let formatter = HeaderFormatter(headerLevel: .h1)
        storage.toggle(formatter: formatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<h1>Apply a header</h1>")

        storage.toggle(formatter:formatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "<p>Apply a header</p>")
    }

    /// This test ensures that when applying a header style on top of another style the replacement occurs correctly.
    ///
    func testSwitchHeaderStyleToggle() {
        storage.append(NSAttributedString(string: "Apply a header"))
        let formatterH1 = HeaderFormatter(headerLevel: .h1)
        let formatterH2 = HeaderFormatter(headerLevel: .h2)
        storage.toggle(formatter: formatterH1, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<h1>Apply a header</h1>")

        storage.toggle(formatter:formatterH2, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "<h2>Apply a header</h2>")
    }

    /// This test check if the insertion of two images one after the other works correctly and to img tag are inserted
    ///
    func testInsertOneImageAfterTheOther() {
        let firstAttachment = ImageAttachment(identifier: UUID().uuidString, url: URL(string:"https://wordpress.com")!)
        storage.replaceCharacters(in: NSRange(location:0, length: 0), with: NSAttributedString(attachment: firstAttachment))

        let secondAttachment = ImageAttachment(identifier: UUID().uuidString, url: URL(string:"https://wordpress.org")!)
        storage.replaceCharacters(in: NSRange(location:1, length: 0), with: NSAttributedString(attachment: secondAttachment))

        let html = storage.getHTML()

        XCTAssertEqual(firstAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(secondAttachment.url, URL(string: "https://wordpress.org"))
        XCTAssertEqual(html, "<p><img src=\"https://wordpress.com\"><img src=\"https://wordpress.org\"></p>")
    }

    /// This test check if the insertion of two images one after the other works correctly and to img tag are inserted
    ///
    func testInsertSameImageAfterTheOther() {
        let firstAttachment = ImageAttachment(identifier: UUID().uuidString, url: URL(string:"https://wordpress.com")!)
        storage.replaceCharacters(in: NSRange(location:0, length: 0), with: NSAttributedString(attachment: firstAttachment))

        let secondAttachment = ImageAttachment(identifier: UUID().uuidString, url: URL(string:"https://wordpress.com")!)
        storage.replaceCharacters(in: NSRange(location:1, length: 0), with: NSAttributedString(attachment: secondAttachment))
        let html = storage.getHTML()

        XCTAssertEqual(firstAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(secondAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(html, "<p><img src=\"https://wordpress.com\"><img src=\"https://wordpress.com\"></p>")
    }

    /// This test verifies if the `removeTextAttachements` call effectively nukes all of the TextAttachments present
    /// in the storage.
    ///
    func testRemoveAllTextAttachmentsNukeTextAttachmentInstances() {
        let sample = NSMutableAttributedString(string: "Some string here")
        storage.append(sample)

        // New string with 10 attachments
        var identifiers = [String]()
        let count = 10

        for _ in 0 ..< count {
            let sourceURL = URL(string:"test://")!
            let attachment = ImageAttachment(identifier: UUID().uuidString, url: sourceURL)
            storage.replaceCharacters(in: NSRange(location:0, length: 0), with: NSAttributedString(attachment: attachment))

            identifiers.append(attachment.identifier)
        }


        // Verify the attachments are there
        for identifier in identifiers {
            XCTAssertNotNil(storage.attachment(withId: identifier))
        }

        // Nuke
        storage.removeMediaAttachments()

        // Verify the attachments are there
        for identifier in identifiers {
            XCTAssertNil(storage.attachment(withId: identifier))
        }
    }

    /// This test verifies if we can delete all the content from a storage object that has html with a comment
    ///
    func testDeleteAllSelectionWhenContentHasComments() {
        let commentString = "This is a comment"
        let html = "<!--\(commentString)-->"
        storage.setHTML(html, withDefaultFontDescriptor: UIFont.systemFont(ofSize: 14).fontDescriptor)
        storage.replaceCharacters(in: NSRange(location: 0, length: 1), with: NSAttributedString(string: ""))

        let resultHTML = storage.getHTML()

        XCTAssertEqual(String(), resultHTML)
    }
}
