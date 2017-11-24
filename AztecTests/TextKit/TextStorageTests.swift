import Foundation
import XCTest
@testable import Aztec


class TextStorageTests: XCTestCase {

    /// Test Storage
    ///
    var storage: TextStorage!

    /// HTML Serializer
    ///
    let serializer = DefaultHTMLSerializer()

    /// Test Attachments Delegate
    ///
    var mockDelegate: MockAttachmentsDelegate!

    /// Default Text Attributes
    ///
    let defaultAttributes: [NSAttributedStringKey: Any] = [.foregroundColor: UIColor.black,
                                                           .font: UIFont.systemFont(ofSize: 14),
                                                           .paragraphStyle: ParagraphStyle.default]

    override func setUp() {
        super.setUp()

        mockDelegate = MockAttachmentsDelegate()
        storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate
    }


    // MARK: - Test Traits

    func testFontTraitExistsAtIndex() {
        let attributes: [AttributedStringKey: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10)
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
        let attributes: [AttributedStringKey: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10)
        ]

        storage.append(NSAttributedString(string: "foo"))
        storage.append(NSAttributedString(string: "bar", attributes: attributes))
        storage.append(NSAttributedString(string: "baz"))

        XCTAssert(storage.fontTrait(.traitBold, spansRange: NSRange(location: 3, length: 3)))
        XCTAssert(!storage.fontTrait(.traitBold, spansRange: NSRange(location: 0, length: 9)))

    }

    func testToggleTraitInRange() {
        let attributes: [AttributedStringKey: Any] = [.font: UIFont.boldSystemFont(ofSize: 10)]

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

        func storage(_ storage: TextStorage, urlFor imageAttachment: ImageAttachment) -> URL? {
            return URL(string:"test://")
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

        let html = storage.getHTML(serializer: serializer)

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

        let html = storage.getHTML(serializer: serializer)
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
        storage.setHTML(initialHTML, defaultAttributes: defaultAttributes)

        // Find the Attachment
        var theAttachment: HTMLAttachment!
        storage.enumerateAttachmentsOfType(HTMLAttachment.self, range: nil) { (attachment, _, _) in
            theAttachment = attachment
        }

        // Update
        XCTAssertNotNil(theAttachment)
        theAttachment.rawHTML = updatedHTML

        // Verify
        XCTAssertEqual(storage.getHTML(serializer: serializer), finalHTML)
    }

    func testBlockquoteToggle1() {
        storage.append(NSAttributedString(string: "Apply a blockquote"))

        let blockquoteFormatter = BlockquoteFormatter()
        storage.toggle(formatter: blockquoteFormatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "<blockquote>Apply a blockquote</blockquote>")

        storage.toggle(formatter: blockquoteFormatter, at: storage.rangeOfEntireString)

        html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "<p>Apply a blockquote</p>")
    }

    func testBlockquoteToggle2() {
        storage.append(NSAttributedString(string: "Hello 🌎!\nApply a blockquote!"))
        let blockquoteFormatter = BlockquoteFormatter()

        let range = NSRange(location: 9, length: 19)
        let utf16Range = storage.string.utf16NSRange(from: range)

        storage.toggle(formatter: blockquoteFormatter, at: utf16Range)

        let html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "<p>Hello 🌎!</p><blockquote>Apply a blockquote!</blockquote>")
    }

    func testLinkInsert() {
        storage.append(NSAttributedString(string: "Apply a link"))
        let linkFormatter = LinkFormatter()
        linkFormatter.attributeValue = URL(string: "www.wordpress.com")!
        storage.toggle(formatter: linkFormatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "<p><a href=\"www.wordpress.com\">Apply a link</a></p>")

        storage.toggle(formatter:linkFormatter, at: storage.rangeOfEntireString)

        html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "<p>Apply a link</p>")
    }

    func testHeaderToggle() {
        storage.append(NSAttributedString(string: "Apply a header"))
        let formatter = HeaderFormatter(headerLevel: .h1)
        storage.toggle(formatter: formatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "<h1>Apply a header</h1>")

        storage.toggle(formatter:formatter, at: storage.rangeOfEntireString)

        html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "Apply a header")
    }

    /// This test verifies that after merging two lines with different Header Format, the Font Size will
    /// be unified across them.
    ///
    func testHeaderFontSizeIsFixedAfterTwoLinesAreMerged() {
        let l1String = NSAttributedString(string: "H1 Line")
        let l2String = NSAttributedString(string: "\nNormal Line")

        storage.append(l1String)
        storage.append(l2String)

        // #Line 1 > H1
        // #Line 2 > H2
        let h1formatter = HeaderFormatter(headerLevel: .h1)
        let h2formatter = HeaderFormatter(headerLevel: .h2)

        let l1Range = NSRange(location: 0, length: l1String.length)
        let newlineRange = NSRange(location: l1Range.length, length: 1)
        let l2Range = NSRange(location: newlineRange.location + newlineRange.length, length: l2String.length - newlineRange.length)

        storage.toggle(formatter: h1formatter, at: l1Range)
        storage.toggle(formatter: h2formatter, at: l2Range)

        // Verify HTML so Far
        let html = storage.getHTML(serializer: serializer)
        XCTAssertEqual(html, "<h1>H1 Line</h1><h2>Normal Line</h2>")

        // Nuke the Newline Character
        storage.deleteCharacters(in: newlineRange)

        // Verify HTML
        let fixedHTML = storage.getHTML(serializer: serializer)
        XCTAssertEqual(fixedHTML, "<h1>H1 LineNormal Line</h1>")

        // Verify Font
        var oldFont: UIFont?

        for i in 0 ..< storage.length {
            let currentFont = storage.attribute(.font, at: i, effectiveRange: nil) as? UIFont
            XCTAssert(oldFont == nil || oldFont == currentFont)
            oldFont = currentFont
        }
    }

    /// This test ensures that when applying a header style on top of another style the replacement occurs correctly.
    ///
    func testSwitchHeaderStyleToggle() {
        storage.append(NSAttributedString(string: "Apply a header"))
        let formatterH1 = HeaderFormatter(headerLevel: .h1)
        let formatterH2 = HeaderFormatter(headerLevel: .h2)
        storage.toggle(formatter: formatterH1, at: storage.rangeOfEntireString)

        var html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "<h1>Apply a header</h1>")

        storage.toggle(formatter:formatterH2, at: storage.rangeOfEntireString)

        html = storage.getHTML(serializer: serializer)

        XCTAssertEqual(html, "<h2>Apply a header</h2>")
    }

    /// This test check if the insertion of two images one after the other works correctly and to img tag are inserted
    ///
    func testInsertOneImageAfterTheOther() {
        let firstAttachment = ImageAttachment(identifier: UUID().uuidString, url: URL(string:"https://wordpress.com")!)
        storage.replaceCharacters(in: NSRange(location:0, length: 0), with: NSAttributedString(attachment: firstAttachment))

        let secondAttachment = ImageAttachment(identifier: UUID().uuidString, url: URL(string:"https://wordpress.org")!)
        storage.replaceCharacters(in: NSRange(location:1, length: 0), with: NSAttributedString(attachment: secondAttachment))

        let html = storage.getHTML(serializer: serializer)

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
        let html = storage.getHTML(serializer: serializer)

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

        let defaultAttributes: [AttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                             .paragraphStyle: ParagraphStyle.default]

        storage.setHTML(html, defaultAttributes: defaultAttributes)
        storage.replaceCharacters(in: NSRange(location: 0, length: 1), with: NSAttributedString(string: ""))

        let resultHTML = storage.getHTML(serializer: serializer)

        XCTAssertEqual(String(), resultHTML)
    }

    /// This test verifies that, whenever a NSAttributedString is inserted inline (and has a different font), the ParagraphStyle
    /// attribute will be 'fixed'. This translates into: there won't be different instances of ParagraphStyle for characters in the same line.
    /// This has been tracked to be causing display issues when using the `Chinese (Simplified) Pinyin` keyboard.
    ///
    /// Reference: https://github.com/wordpress-mobile/AztecEditor-iOS/issues/811
    ///
    func testAttributesAreFixedWheneverStringsWithDifferentAttributesAreInsertedOnTheSameLine() {

        /// Attributes
        ///
        let formatterH1 = HeaderFormatter(headerLevel: .h1)
        let headerAttributes = formatterH1.apply(to: defaultAttributes, andStore: nil)

        /// Precondition: Newline at the top
        ///
        let newlineString = NSAttributedString(string: "\n", attributes: defaultAttributes)

        storage.replaceCharacters(in: .zero, with: newlineString)

        /// Insert + Replace: with H1 Attributes
        ///
        let insertionRange1 = NSRange(location: 1, length: 0)
        let characterRange1 = NSRange(location: 1, length: 1)

        let chineseStringH1 = NSAttributedString(string: "上", attributes: headerAttributes)
        let regularStringH1 = NSAttributedString(string: "s", attributes: headerAttributes)

        storage.replaceCharacters(in: insertionRange1, with: regularStringH1)
        storage.replaceCharacters(in: characterRange1, with: chineseStringH1)

        /// After the two calls above, when typing, TextView will not relay properly apply the `H1` attributes. We'll simulate that:
        ///
        let chineseStringNormal = NSAttributedString(string: "上", attributes: defaultAttributes)
        let regularStringNormal = NSAttributedString(string: "s", attributes: defaultAttributes)

        let insertionRange2 = NSRange(location: 2, length: 0)
        let characterRange2 = NSRange(location: 2, length: 1)

        storage.replaceCharacters(in: insertionRange2, with: regularStringNormal)
        storage.replaceCharacters(in: characterRange2, with: chineseStringNormal)

        /// Context:
        /// storage.string at this point contains "\n上上"
        ///
        /// PROBLEM:
        /// If characters 1 and 2 have different paragraphStyles, the second character may not get properly displayed by the TextView.
        ///
        let paragraphStyle1 = storage.attribute(.paragraphStyle, at: characterRange1.location, effectiveRange: nil) as! NSParagraphStyle
        let paragraphStyle2 = storage.attribute(.paragraphStyle, at: characterRange2.location, effectiveRange: nil) as! NSParagraphStyle

        XCTAssertEqual(paragraphStyle1, paragraphStyle2)
    }
}
