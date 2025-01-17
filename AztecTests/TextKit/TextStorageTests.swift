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
        let attributes: [NSAttributedString.Key: Any] = [
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
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10)
        ]

        storage.append(NSAttributedString(string: "foo"))
        storage.append(NSAttributedString(string: "bar", attributes: attributes))
        storage.append(NSAttributedString(string: "baz"))

        XCTAssert(storage.fontTrait(.traitBold, spansRange: NSRange(location: 3, length: 3)))
        XCTAssert(!storage.fontTrait(.traitBold, spansRange: NSRange(location: 0, length: 9)))

    }

    func testToggleTraitInRange() {
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 10)]

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

        func storage(_ storage: TextStorage, deletedAttachment attachment: MediaAttachment) {
            deletedAttachmendIDCalledWithString = attachment.identifier
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
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                             .paragraphStyle: ParagraphStyle.default]
        
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
        let html = storage.getHTML()
        XCTAssertEqual(html, "<h1>H1 Line</h1><h2>Normal Line</h2>")

        // Nuke the Newline Character
        storage.deleteCharacters(in: newlineRange)

        // Verify HTML
        let fixedHTML = storage.getHTML()
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

        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                             .paragraphStyle: ParagraphStyle.default]
        
        storage.setHTML(html, defaultAttributes: defaultAttributes)
        storage.replaceCharacters(in: NSRange(location: 0, length: 1), with: NSAttributedString(string: ""))

        let resultHTML = storage.getHTML()

        XCTAssertEqual(String(), resultHTML)
    }

    func testCommentFollowedByBlockLevelElements() {
        let elementsToTest: [Element] = [.p, .pre, .div, .h2, .h3, .h4, .h5, .h6]
        
        for element in elementsToTest {
            let html = "<!-- comment --><\(element.rawValue) class=\"custom_hr\">Some content</\(element.rawValue)>"
            let expectedHTML = "<p><!-- comment --></p><\(element.rawValue) class=\"custom_hr\">Some content</\(element.rawValue)>"
            let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                   .paragraphStyle: ParagraphStyle.default]
            storage.setHTML(html, defaultAttributes: defaultAttributes)
            let outputHTML = storage.getHTML()
            
            XCTAssertEqual(expectedHTML, outputHTML)
        }
    }

    func testElementFollowedByComment() {
        let elementsToTest: [Element] = [.p, .pre, .div, .h2, .h3, .h4, .h5, .h6]

        for element in elementsToTest {
            let html = "<\(element.rawValue) class=\"custom_hr\"><!-- comment -->Some content</\(element.rawValue)>"
            let expectedHTML = "<\(element.rawValue) class=\"custom_hr\"><!-- comment -->Some content</\(element.rawValue)>"
            let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                   .paragraphStyle: ParagraphStyle.default]
            storage.setHTML(html, defaultAttributes: defaultAttributes)
            let outputHTML = storage.getHTML()

            XCTAssertEqual(expectedHTML, outputHTML)
        }
    }

    func testMultipleComments() {
        let html = "<!-- comment 1 --><!-- comment 2 -->Some content<!-- comment 3-->"
        let expectedHTML = "<p><!-- comment 1 --><!-- comment 2 -->Some content<!-- comment 3--></p>"
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                   .paragraphStyle: ParagraphStyle.default]
        storage.setHTML(html, defaultAttributes: defaultAttributes)
        let outputHTML = storage.getHTML()

        XCTAssertEqual(expectedHTML, outputHTML)
    }

    func testCommentSurroundingBlockLevelElements() {
        let elementsToTest: [Element] = [.p, .pre, .div, .h2, .h3, .h4, .h5, .h6, .blockquote]

        for element in elementsToTest {
            let html = "<!-- comment --><\(element.rawValue) class=\"custom_hr\">Some content</\(element.rawValue)><!-- comment -->"
            let expectedHTML = "<p><!-- comment --></p><\(element.rawValue) class=\"custom_hr\">Some content</\(element.rawValue)><p><!-- comment --></p>"
            let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                   .paragraphStyle: ParagraphStyle.default]
            storage.setHTML(html, defaultAttributes: defaultAttributes)
            let outputHTML = storage.getHTML()

            XCTAssertEqual(expectedHTML, outputHTML)
        }
    }

    func testBlockquotesWithCite() {
        let html = """
<blockquote class="wp-block-quote is-large"><p>Take comfort in the fact that you 'can' keep your current publishing flow... and then take some time to explore the possibilities that Gutenberg opens up to you.</p><cite>By M</cite></blockquote>
"""
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                               .paragraphStyle: ParagraphStyle.default]
        storage.setHTML(html, defaultAttributes: defaultAttributes)
        let outputHTML = storage.getHTML()
        
        XCTAssertEqual(html, outputHTML)
    }

    func testSingleSpaceBetweenElements() {
        let html = "<p><strong>WordPress</strong> <em>App</em></p>"

        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                               .paragraphStyle: ParagraphStyle.default]
        storage.setHTML(html, defaultAttributes: defaultAttributes)
        let outputHTML = storage.getHTML()

        XCTAssertEqual(html, outputHTML)
    }

    func testListElementAttributes() {
        let html = """
<ul class="wp-block-gallery alignnone columns-1 is-cropped">
  <li class="blocks-gallery-item">
    <figure><img src="https://sandbox.koke.me/wp-content/uploads/2018/05/fullsizeoutput_52f7.jpeg" class="alignnone" data-id="96" alt=""></figure>
  </li>
</ul>
"""
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                               .paragraphStyle: ParagraphStyle.default]
        storage.setHTML(html, defaultAttributes: defaultAttributes)
        let outputHTML = storage.getHTML(prettify: true)

        XCTAssertEqual(html, outputHTML)
    }

    func testListWithNestedLists() {
        let initialHTML = "<ul><li>One</li><li><ul><li>Two</li></ul></li></ul>"

        // Setup
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                .paragraphStyle: ParagraphStyle.default]

        storage.setHTML(initialHTML, defaultAttributes: defaultAttributes)
        let expectedResult = "One"+String(.paragraphSeparator)+String(.paragraphSeparator)+"Two"
        let result = String(storage.mutableString)

        XCTAssertEqual(expectedResult, result)
    }

    func testEmptyListOutput() {
        let initialHTML = "<ul><li></li></ul>"

        // Setup
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                .paragraphStyle: ParagraphStyle.default]

        storage.setHTML(initialHTML, defaultAttributes: defaultAttributes)
        var expectedResult = String(.paragraphSeparator)
        var result = String(storage.string)

        XCTAssertEqual(expectedResult, result)

        storage.htmlConverter.characterToReplaceLastEmptyLine = Character(.zeroWidthSpace)

        storage.setHTML(initialHTML, defaultAttributes: defaultAttributes)
        expectedResult = String(.zeroWidthSpace)
        result = String(storage.string)

        XCTAssertEqual(expectedResult, result)
    }

    func testCiteOutput() {
        let initialHTML = "<cite>Hello<br></cite>"

        // Setup
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                .paragraphStyle: ParagraphStyle.default]

        storage.setHTML(initialHTML, defaultAttributes: defaultAttributes)
        var expectedResult = String("Hello")+String(.lineSeparator)
        var result = String(storage.string)

        XCTAssertEqual(expectedResult, result)

        storage.htmlConverter.characterToReplaceLastEmptyLine = Character(.zeroWidthSpace)

        storage.setHTML(initialHTML, defaultAttributes: defaultAttributes)
        expectedResult = String("Hello")+String(.lineSeparator)
        result = String(storage.string)

        XCTAssertEqual(expectedResult, result)
    }

    /// Verifies that the all header formatting is removed when Header as styles (bold or italic)
    ///
    func testAllHeaderFormattingIsRemoved() {
        let initialHTML = "<p>Hello World</p>"

        // Setup
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                .paragraphStyle: ParagraphStyle.default]
        storage.setHTML(initialHTML, defaultAttributes: defaultAttributes)

        let formatterH1 = HeaderFormatter(headerLevel: .h1)
        let formatterBold = BoldWithShadowForHeadingFormatter()

        formatterH1.applyAttributes(to: storage, at: NSRange(location:0, length: 0))
        formatterBold.applyAttributes(to: storage, at: NSRange(location: 6, length: 3))

        formatterH1.removeAttributes(from: storage, at: NSRange(location:0, length: 0))

        storage.enumerateAttributes(in: storage.rangeOfEntireString, options: []) { (attributes, range, stop) in
            let font = attributes[.font] as! UIFont
            XCTAssert(font.pointSize == 14)
        }
    }

    /// Verifies that spaces are not collapsed
    ///
    func testConverterCollapsesSpacesText() {
        let initialHTML = "<p>  Hello  <br>   <strong>World</strong>  </p>"

        // Setup
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                                .paragraphStyle: ParagraphStyle.default]

        storage.htmlConverter.shouldCollapseSpaces = false
        storage.setHTML(initialHTML, defaultAttributes: defaultAttributes)

        let expectedResult = "<p>  Hello  <br>   <strong>World</strong>  </p>"
        let result = storage.getHTML()
        XCTAssertEqual(expectedResult, result)
    }

    /// Verifies that missing Heading attributes are retained on string replacements when appropriate
    ///
    func testMissingHeadingAttributeIsRetained() {
        let formatter = HeaderFormatter(headerLevel: .h2)
        storage.replaceCharacters(in: storage.rangeOfEntireString, with: "Hello i'm a header")
        formatter.applyAttributes(to: storage, at: storage.rangeOfEntireString)

        let originalAttributes = storage.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(storage.string, "Hello i'm a header")
        XCTAssertEqual(originalAttributes.count, 3)
        XCTAssertNotNil(originalAttributes[.headingRepresentation])

        let autoCorrectedAttributes = originalAttributes.filter { $0.key != .headingRepresentation }

        let autoCorrectedString = NSAttributedString(
            string: "I'm",
            attributes: autoCorrectedAttributes
        )

        let range = NSRange(location: 6, length: 3)
        storage.replaceCharacters(in: range, with: autoCorrectedString)

        let finalAttributes = storage.attributes(at: range.location, effectiveRange: nil)
        XCTAssertEqual(storage.string, "Hello I'm a header")
        XCTAssertEqual(originalAttributes.keys, finalAttributes.keys)
    }

    /// Verifies that converting a Heading to a Paragraph doesn't retain the heading attribute
    ///
    func testHeadingToParagraphDoesNotRetainHeadingAttribute() {
        let headerFormatter = HeaderFormatter(headerLevel: .h2)
        storage.replaceCharacters(in: storage.rangeOfEntireString, with: "Hello I'm a header")
        headerFormatter.applyAttributes(to: storage, at: storage.rangeOfEntireString)

        let originalAttributes = storage.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(storage.string, "Hello I'm a header")
        XCTAssertNotNil(originalAttributes[.headingRepresentation])

        let paragraphAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .paragraphStyle: ParagraphStyle.default
        ]

        let paragraphString = NSAttributedString(
            string: "Hello I'm a paragraph",
            attributes: paragraphAttributes
        )
        storage.replaceCharacters(in: storage.rangeOfEntireString, with: paragraphString)

        let finalAttributes = storage.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(storage.string, "Hello I'm a paragraph")
        XCTAssertNil(finalAttributes[.headingRepresentation])
    }

    /// Verifies that missing Mark attributes are retained on string replacements when appropriate
    ///
    func testMissingMarkAttributeIsRetained() {
        let formatter = MarkFormatter()
        storage.replaceCharacters(in: storage.rangeOfEntireString, with: "Hello i'm a text highlighted")
        formatter.applyAttributes(to: storage, at: storage.rangeOfEntireString)

        let originalAttributes = storage.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(storage.string, "Hello i'm a text highlighted")
        XCTAssertEqual(originalAttributes.count, 2)
        XCTAssertNotNil(originalAttributes[.markHtmlRepresentation])

        let autoCorrectedAttributes = originalAttributes.filter { $0.key != .markHtmlRepresentation }

        let autoCorrectedString = NSAttributedString(
            string: "I'm",
            attributes: autoCorrectedAttributes
        )

        let range = NSRange(location: 6, length: 3)
        storage.replaceCharacters(in: range, with: autoCorrectedString)

        let finalAttributes = storage.attributes(at: range.location, effectiveRange: nil)
        XCTAssertEqual(storage.string, "Hello I'm a text highlighted")
        XCTAssertEqual(originalAttributes.keys, finalAttributes.keys)
    }
}
