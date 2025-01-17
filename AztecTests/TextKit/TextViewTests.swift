import XCTest
@testable import Aztec
import MobileCoreServices

class TextViewTests: XCTestCase {

    struct Constants {
        static let sampleText0 = "Lorem ipsum sarasum naradum taradum insumun"
        static let sampleText1 = " patronum sitanum elanum zoipancoiamum."
    }

    let attachmentDelegate = TextViewStubAttachmentDelegate()

    override func setUp() {
        super.setUp()

        // Ensure there is no shared state between tests
        UIPasteboard.forTesting.reset()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    // MARK: - TextView construction

    func createTextViewWithContent() -> TextView {
        let paragraph = "Lorem ipsum dolar sit amet.\n"
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())
        richTextView.textAttachmentDelegate = attachmentDelegate
        let attributes = [NSAttributedString.Key.paragraphStyle : NSParagraphStyle()]
        let templateString = NSMutableAttributedString(string: paragraph, attributes: attributes)

        let attrStr = NSMutableAttributedString()
        attrStr.append(templateString)
        attrStr.append(templateString)
        attrStr.append(templateString)
        richTextView.attributedText = attrStr
        
        return richTextView
    }

    // MARK: - Configuration

    func testTextViewReferencesStorage() {

        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())

        textView.text = "Foo"
        XCTAssert(textView.text == "Foo")
        XCTAssert(textView.text == textView.textStorage.string)
        XCTAssert(textView.attributedText == textView.textStorage)

        textView.attributedText = NSAttributedString(string: "Bar")
        XCTAssert(textView.text == "Bar")
        XCTAssert(textView.text == textView.textStorage.string)
        XCTAssert(textView.attributedText == textView.textStorage)

        XCTAssert(textView.textStorage == textView.layoutManager.textStorage)
        XCTAssert(textView.textStorage == textView.textContainer.layoutManager!.textStorage)
        XCTAssert(textView.textStorage.isKind(of: TextStorage.self))
    }


    // MARK: - Test Index Wrangling

    func testMaxIndex() {
        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())

        textView.text = "foo"

        let count = textView.text!.count
        let maxIndex = count - 1

        // Test upper and lower bounds
        XCTAssert(maxIndex == textView.maxIndex(100))
        XCTAssert(0 == textView.maxIndex(0))
    }

    func testAdjustedIndex() {
        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())

        textView.text = "foobarbaz"

        let count = textView.text!.count
        let maxIndex = count - 1

        // Test upper and lower bounds.
        // Remember that an adjusted character index should be one less than 
        // the NSRange.location.
        XCTAssert(maxIndex - 1 == textView.adjustedIndex(100))
        XCTAssert(0 == textView.adjustedIndex(0))
        XCTAssert(0 == textView.adjustedIndex(1))
        XCTAssert(1 == textView.adjustedIndex(2))
    }

    // MARK: - Retrieve Format Identifiers

    func testFormattingIdentifiersSpanningRange() {
        let textView = TextViewStub(withHTML: "foo<b>bar</b>baz")

        let range = NSRange(location: 3, length: 3)
        let identifiers = textView.formattingIdentifiersSpanningRange(range)

        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers.contains(.bold))
    }

    func testFormattingIdentifiersAtIndex() {
        let textView = TextViewStub(withHTML: "foo<b>bar</b>baz")

        var identifiers = textView.formattingIdentifiersAtIndex(4)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers.contains(.bold))

        identifiers = textView.formattingIdentifiersAtIndex(5)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers.contains(.bold))

        identifiers = textView.formattingIdentifiersAtIndex(6)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers.contains(.bold))


        identifiers = textView.formattingIdentifiersAtIndex(0)
        XCTAssert(identifiers.count == 0)

        identifiers = textView.formattingIdentifiersAtIndex(3)
        XCTAssert(identifiers.count == 0)

        identifiers = textView.formattingIdentifiersAtIndex(7)
        XCTAssert(identifiers.count == 0)
    }


    // MARK: - Toggle Attributes

    func testToggleBold() {
        let textView = TextViewStub(withHTML: "foo<b>bar</b>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.bold))

        textView.toggleBold(range: range)

        XCTAssert(!textView.formattingIdentifiersSpanningRange(range).contains(.bold))

        textView.toggleBold(range: range)

        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.bold))
    }

    func testToggleItalic() {
        let textView = TextViewStub(withHTML: "foo<i>bar</i>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.italic))

        textView.toggleItalic(range: range)

        XCTAssert(!textView.formattingIdentifiersSpanningRange(range).contains(.italic))

        textView.toggleItalic(range: range)

        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.italic))
    }

    func testToggleUnderline() {
        let textView = TextViewStub(withHTML: "foo<u>bar</u>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.underline))

        textView.toggleUnderline(range: range)

        XCTAssert(!textView.formattingIdentifiersSpanningRange(range).contains(.underline))

        textView.toggleUnderline(range: range)

        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.underline))
    }

    func testToggleStrike() {
        let textView = TextViewStub(withHTML: "foo<strike>bar</strike>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.strikethrough))

        textView.toggleStrikethrough(range: range)

        XCTAssert(!textView.formattingIdentifiersSpanningRange(range).contains(.strikethrough))

        textView.toggleStrikethrough(range: range)

        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.strikethrough))
    }

    func testToggleBlockquote() {
        let textView = createTextViewWithContent()
        let length = textView.text.count
        let range = NSRange(location: 0, length: length)

        textView.toggleBlockquote(range: range)

        XCTAssert(textView.formattingIdentifiersAtIndex(1).contains(.blockquote))
        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.blockquote))

        textView.toggleBlockquote(range: range)

        XCTAssert(!textView.formattingIdentifiersAtIndex(1).contains(.blockquote))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(range).contains(.blockquote))
    }

    func testToggleOrderedList() {
        let textView = createTextViewWithContent()
        let length = textView.text.count
        let range = NSRange(location: 0, length: length)

        textView.toggleOrderedList(range: range)

        XCTAssert(textView.formattingIdentifiersAtIndex(0).contains(.orderedlist))
        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.orderedlist))

        textView.toggleOrderedList(range: range)

        XCTAssert(!textView.formattingIdentifiersAtIndex(0).contains(.orderedlist))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(range).contains(.orderedlist))
    }

    func testToggleUnorderedList() {
        let textView = createTextViewWithContent()
        let length = textView.text.count
        let range = NSRange(location: 0, length: length)

        textView.toggleUnorderedList(range: range)

        XCTAssert(textView.formattingIdentifiersAtIndex(0).contains(.unorderedlist))
        XCTAssert(textView.formattingIdentifiersSpanningRange(range).contains(.unorderedlist))

        textView.toggleOrderedList(range: range)

        XCTAssert(!textView.formattingIdentifiersAtIndex(0).contains(.unorderedlist))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(range).contains(.unorderedlist))
    }

    /// This test was created to prevent regressions related to this issue:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/350
    ///
    func testToggleBlockquoteAndStrikethrough() {
        let textView = TextViewStub()

        textView.toggleStrikethrough(range: NSRange.zero)
        textView.toggleBlockquote(range: NSRange.zero)

        // The test not crashing would be successful.
    }


    // MARK: - Test Attributes Exist

    func check(textView: TextView, range:NSRange, forIndentifier identifier: FormattingIdentifier) -> Bool {
        return textView.formattingIdentifiersSpanningRange(range).contains(identifier)
    }

    func testBoldSpansRange() {
        let textView = TextViewStub(withHTML: "foo<b>bar</b>baz")

        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.bold))
        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.bold))
        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.bold))

        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.bold))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.bold))
    }

    func testItalicSpansRange() {
        let textView = TextViewStub(withHTML: "foo<i>bar</i>baz")

        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.italic))
        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.italic))
        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.italic))

        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.italic))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.italic))
    }

    func testUnderlineSpansRange() {
        let textView = TextViewStub(withHTML: "foo<u>bar</u>baz")

        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.underline))
        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.underline))
        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.underline))

        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.underline))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.underline))
    }

    func testStrikethroughSpansRange() {
        let textView = TextViewStub(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.strikethrough))
        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.strikethrough))
        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.strikethrough))

        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.strikethrough))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.strikethrough))
    }

    func testBlockquoteSpansRange() {
        let textView = createTextViewWithContent()
        let range = NSRange(location: 0, length: 1)
        let length = "Lorem ipsum dolar sit amet.\n".count

        textView.toggleBlockquote(range: range)

        XCTAssert(textView.formattingIdentifiersSpanningRange(NSRange(location: 0, length: length)).contains(.blockquote))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 0, length: length + 1)).contains(.blockquote))
        XCTAssert(!textView.formattingIdentifiersSpanningRange(NSRange(location: 1, length: length)).contains(.blockquote))
    }

    func testBoldAtIndex() {
        let textView = TextViewStub(withHTML: "foo<b>bar</b>baz")

        XCTAssert(textView.formattingIdentifiersAtIndex(4).contains(.bold))
        XCTAssert(textView.formattingIdentifiersAtIndex(5).contains(.bold))
        XCTAssert(textView.formattingIdentifiersAtIndex(6).contains(.bold))

        XCTAssert(!textView.formattingIdentifiersAtIndex(2).contains(.bold))
        XCTAssert(!textView.formattingIdentifiersAtIndex(7).contains(.bold))
    }

    func testItalicAtIndex() {
        let textView = TextViewStub(withHTML: "foo<i>bar</i>baz")

        XCTAssert(textView.formattingIdentifiersAtIndex(4).contains(.italic))
        XCTAssert(textView.formattingIdentifiersAtIndex(5).contains(.italic))
        XCTAssert(textView.formattingIdentifiersAtIndex(6).contains(.italic))

        XCTAssert(!textView.formattingIdentifiersAtIndex(2).contains(.italic))
        XCTAssert(!textView.formattingIdentifiersAtIndex(7).contains(.italic))
    }

    func testUnderlineAtIndex() {
        let textView = TextViewStub(withHTML: "foo<u>bar</u>baz")

        XCTAssert(textView.formattingIdentifiersAtIndex(4).contains(.underline))
        XCTAssert(textView.formattingIdentifiersAtIndex(5).contains(.underline))
        XCTAssert(textView.formattingIdentifiersAtIndex(6).contains(.underline))

        XCTAssert(!textView.formattingIdentifiersAtIndex(2).contains(.underline))
        XCTAssert(!textView.formattingIdentifiersAtIndex(7).contains(.underline))
    }

    func testStrikethroughAtIndex() {
        let textView = TextViewStub(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(textView.formattingIdentifiersAtIndex(4).contains(.strikethrough))
        XCTAssert(textView.formattingIdentifiersAtIndex(5).contains(.strikethrough))
        XCTAssert(textView.formattingIdentifiersAtIndex(6).contains(.strikethrough))

        XCTAssert(!textView.formattingIdentifiersAtIndex(2).contains(.strikethrough))
        XCTAssert(!textView.formattingIdentifiersAtIndex(7).contains(.strikethrough))
    }

    func testBlockquoteAtIndex() {
        let textView = createTextViewWithContent()
        let range = NSRange(location: 0, length: 1)

        XCTAssert(!textView.formattingIdentifiersAtIndex(1).contains(.blockquote))

        textView.toggleBlockquote(range: range)

        XCTAssert(textView.formattingIdentifiersAtIndex(1).contains(.blockquote))

        textView.toggleBlockquote(range: range)

        XCTAssert(!textView.formattingIdentifiersAtIndex(1).contains(.blockquote))
    }

    func testColorAttributeAtPosition() {
        let textView = TextViewStub(withHTML: "foo<span style=\"color: #FF0000\">bar</span>baz")

        XCTAssert(textView.attributedText!.attributes(at: 4, effectiveRange: nil).keys.contains(.foregroundColor))
        let color = textView.attributedText!.attributes(at: 4, effectiveRange: nil)[.foregroundColor] as! UIColor
        XCTAssertEqual(color, UIColor(hexString: "#FF0000"))
    }

    // MARK: - Adding newlines

    /// Tests that entering a newline in an empty editor does not crash it.
    ///
    /// Added to avoid regressions to the bug reported here:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/352
    ///
    func testAddingNewlineOnEmptyEditor() {
        let textView = TextViewStub(withHTML: "")

        textView.insertText("\n")
    }

    /// Tests that a visual newline is not added at EoF
    ///
    func testNewlineNotAddedAtEof() {
        let textView = TextViewStub(withHTML: "<p>Testing <b>bold</b> newlines</p>")

        XCTAssertEqual(textView.text, "Testing bold newlines")
    }

    /// Tests that the visual newline is shown at the correct position.
    ///
    /// Added to avoid regressions to the bug reported here:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/387
    ///
    func testNewlineRenderedAtTheCorrectPosition() {
        let textView = TextViewStub(withHTML: "<p>Testing <b>bold</b> newlines</p>Hey!")

        XCTAssertEqual(textView.text, "Testing bold newlines\(String(.paragraphSeparator))Hey!")
    }


    // MARK: - Deleting newlines

    /// Tests that deleting a newline works by merging the component around it.
    ///
    /// Input:
    ///     - Initial HTML: "<p>Hello</p><p>World!</p>"
    ///     - Deletion range: (loc: 5, len 1)
    ///
    /// Output:
    ///     - Final HTML: "<p>HelloWorld!</p>"
    ///
    func testDeleteNewline() {

        let textView = TextViewStub(withHTML: "<p>Hello</p><p>World!</p>")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 5)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(), "<p>HelloWorld!</p>")
    }

    /// Tests that deleting a newline works by merging the component around it.
    ///
    /// Input:
    ///     - Initial HTML: "Hello<p>World!</p>"
    ///     - Deletion range: (loc: 5, len 1)
    ///
    /// Output:
    ///     - Final HTML: "HelloWorld!"
    ///
    func testDeleteNewline2() {

        let textView = TextViewStub(withHTML: "Hello<p>World!</p>")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 5)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(), "<p>HelloWorld!</p>")
    }

    /// Tests that deleting a newline works by merging the component around it.
    ///
    /// Input:
    ///     - Initial HTML: "<blockquote>Hello</blockquote><p>World!</p>"
    ///     - Deletion range: (loc: 5, len 1)
    ///
    /// Output:
    ///     - Final HTML: "<blockquote>HelloWorld!</blockquote>"
    ///
    func testDeleteNewline3() {

        let textView = TextViewStub(withHTML: "<blockquote>Hello</blockquote><p>World!</p>")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 5)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(), "<blockquote>HelloWorld!</blockquote>")
    }

    /// Tests that deleting a newline works by merging the component around it.
    ///
    /// Input:
    ///     - Initial HTML: "<p>Hello</p>World!"
    ///     - Deletion range: (loc: 5, len 1)
    ///
    /// Output:
    ///     - Final HTML: "<p>HelloWorld!</p>"
    ///
    func testDeleteNewline4() {

        let textView = TextViewStub(withHTML: "<p>Hello</p>World!")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 5)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(), "<p>HelloWorld!</p>")
    }

    /// Tests that deleting a newline works by merging the component around it.
    ///
    /// Input:
    ///     - Initial HTML: "List<ul><li>first</li><li>second</li><li>third</li></ul>"
    ///     - Deletion range: (loc: 4, len 1)
    ///     - Second deletion range: (loc: 9, len: 1)
    ///     - Third deletion range: (loc: 15, len: 1)
    ///
    /// Output:
    ///     - Final HTML: "Listfirstsecond"
    ///
    func testDeleteNewline5() {

        let textView = TextViewStub(withHTML: "List<ul><li>first</li><li>second</li><li>third</li></ul>")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 4)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")
        
        XCTAssertEqual(textView.getHTML(prettify: false), "<p>Listfirst</p><ul><li>second</li><li>third</li></ul>")

        let rangeStart2 = textView.position(from: textView.beginningOfDocument, offset: 9)!
        let rangeEnd2 = textView.position(from: rangeStart2, offset: 1)!
        let range2 = textView.textRange(from: rangeStart2, to: rangeEnd2)!

        textView.replace(range2, withText: "")

        XCTAssertEqual(textView.getHTML(prettify: false), "<p>Listfirstsecond</p><ul><li>third</li></ul>")

        let rangeStart3 = textView.position(from: textView.beginningOfDocument, offset: 15)!
        let rangeEnd3 = textView.position(from: rangeStart3, offset: 1)!
        let range3 = textView.textRange(from: rangeStart3, to: rangeEnd3)!

        textView.replace(range3, withText: "")

        XCTAssertEqual(textView.getHTML(prettify: false), "<p>Listfirstsecondthird</p>")
    }

    /// Tests that deleting a newline works by merging the component around it.
    ///
    /// Input:
    ///     - Initial HTML: "<ol><li>First</li><li>Second</li></ol><ul><li>Third</li><li>Fourth</li></ul>"
    ///     - Deletion range: (loc: 12, len 1)
    ///
    /// Output:
    ///     - Final HTML: "<ol><li>First</li><li>Second</li><li>Third</li></ol><ul><li>Fourth</li></u"
    ///
    func testDeleteNewline6() {

        let textView = TextViewStub(withHTML: "<ol><li>First</li><li>Second</li></ol>Ahoi<br>Arr!")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 12)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(prettify: false), "<ol><li>First</li><li>SecondAhoi<br>Arr!</li></ol>")
    }

    /// Tests that deleting a newline works at the end of text with paragraph with header before works.
    ///
    /// Input:
    ///     - Initial HTML: "<h1>Header</h1><br>"
    ///     - Deletion range: (loc: 5, len 1)
    ///
    /// Output:
    ///     - Final HTML: "<h1>Header</h1>"
    ///
    func testDeleteNewlineAtEndOfText() {
        let html = "<h1>Header</h1><br>"
        let textView = TextViewStub(withHTML: html)

        let range = NSRange(location: textView.text.count, length:0)
        textView.selectedRange = range
        textView.deleteBackward()

        XCTAssertEqual(textView.getHTML(), "<h1>Header</h1>")
    }

    // MARK: - Backspace

    /// Makes sure that backspacing in the middle of a paragraph doesn't cause any issues with the
    /// paragraph.
    ///
    /// Introduced to avoid regressions with:
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/457
    ///
    func testBackspaceInMiddleOfParagraph() {
        let html = "<p>Hello 🌎 there!</p>"
        let textView = TextViewStub(withHTML: html)

        let newSelectedRange = NSRange(location: 6, length: 1)

        textView.selectedRange = textView.text.utf16NSRange(from: newSelectedRange)
        textView.deleteBackward()
        textView.deleteBackward()

        XCTAssertEqual(textView.getHTML(), "<p>Hello there!</p>")
    }

    // MARK: - Insert links

    /// Tests that inserting a link on an empty textView works.  Also that it doesn't crash the
    /// textView (which was the reason why this test was first introduced).
    ///
    /// Input:
    ///     - Link URL is: "www.wordpress.com"
    ///     - Link Title: "WordPress.com"
    ///     - Insertion range: (loc: 0, len: 0)
    ///
    func testInsertingLinkWorks() {

        let linkUrl = "www.wordpress.com"
        let linkTitle = "WordPress.com"
        let insertionRange = NSRange(location: 0, length: 0)

        let textView = TextViewStub(withHTML: "")
        let url = URL(string: linkUrl)!

        textView.setLink(url, title: linkTitle, inRange: insertionRange)

        XCTAssertEqual(textView.getHTML(), "<p><a href=\"\(linkUrl)\">\(linkTitle)</a></p>")
    }

    /// Tests that inserting a link on the same place twice works properly
    ///
    func testSetLinkTwiceInSameRangeWorks() {

        let linkUrl = "www.wordpress.com"
        let linkTitle = "WordPress.com"
        let insertionRange = NSRange(location: 0, length: linkTitle.utf8.count)

        let textView = TextViewStub(withHTML: linkTitle)
        let url = URL(string: linkUrl)!

        textView.setLink(url, inRange: insertionRange)
        XCTAssertEqual(textView.getHTML(), "<p><a href=\"\(linkUrl)\">\(linkTitle)</a></p>")
        textView.setLink(url, inRange: insertionRange)

        XCTAssertEqual(textView.getHTML(), "<p><a href=\"\(linkUrl)\">\(linkTitle)</a></p>")
    }

    /// Tests that removing a link on the same place twice works properly
    ///
    func testRemoveLinkTwiceInSameRangeWorks() {

        let linkUrl = "www.wordpress.com"
        let linkTitle = "WordPress.com"
        let insertionRange = NSRange(location: 0, length: linkTitle.utf8.count)

        let textView = TextViewStub(withHTML: linkTitle)
        let url = URL(string: linkUrl)!

        textView.setLink(url, inRange: insertionRange)
        XCTAssertEqual(textView.getHTML(), "<p><a href=\"\(linkUrl)\">\(linkTitle)</a></p>")
        textView.removeLink(inRange: insertionRange)
        XCTAssertEqual(textView.getHTML(), "<p>\(linkTitle)</p>")
        textView.removeLink(inRange: insertionRange)

        XCTAssertEqual(textView.getHTML(), "<p>\(linkTitle)</p>")
    }

    func testParsingOfInvalidLink() {
        let html = "<p><a href=\"\\http:\\badlink&?\">link</a></p>"
        let textView = TextViewStub(withHTML: html)

        XCTAssertEqual(textView.getHTML(), html)
    }

    func testParsingOfLinkWithTarget() {
        let html = "<p><a href=\"http://wordpress.com?\" target=\"_blank\">link</a></p>"
        let textView = TextViewStub(withHTML: html)
        let insertionRange = NSRange(location: 0, length: 4)
        let target = textView.linkTarget(forRange: insertionRange)
        XCTAssertEqual(textView.getHTML(), html)

        XCTAssertEqual(target, "_blank")
    }

    func testToggleBlockquoteWriteOneCharAndDelete() {
        let textView = TextViewStub()

        textView.toggleBlockquote(range: NSRange.zero)
        textView.insertText("A")
        textView.deleteBackward()
        // The test not crashing would be successful.
    }

    /// Tests that there is no content loss, when switching to HTML mode, after toggling H1 Style.
    ///
    /// Input:
    ///     - "Header" (inserted character by character).
    ///
    /// Ref.: https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/404
    ///
    func testToggleHeader1DoesNotLooseTheFirstCharacter() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleHeader(.h1, range: .zero)
        textView.insertText("H")
        textView.insertText("e")
        textView.insertText("a")
        textView.insertText("d")
        textView.insertText("e")
        textView.insertText("r")

        XCTAssertEqual(textView.getHTML(), "<h1>Header</h1>")
    }

    /// Tests that there is no HTML Corruption when editing text, after toggling H1 and entering two lines of text.
    ///
    /// Input:
    ///     - "Header\n12" (Inserted character by character)
    ///     - Delete Backwards event.
    ///
    /// Ref. https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/407
    ///
    func testDeletingBackwardAfterTogglingHeaderDoesNotTriggerInvalidHTML() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleHeader(.h1, range: .zero)
        textView.insertText("H")
        textView.insertText("e")
        textView.insertText("a")
        textView.insertText("d")
        textView.insertText("e")
        textView.insertText("r")
        textView.insertText("\n")
        textView.insertText("1")
        textView.insertText("2")
        textView.deleteBackward()

        XCTAssertEqual(textView.getHTML(prettify: false), "<h1>Header</h1><p>1</p>")
    }

    /// Tests that Newline Characters inserted at the middle of a H1 String will cause the newline to loose the style.
    ///
    /// Input:
    ///     - "Header Header"
    ///     - "\n" inserted in between the two words
    /// Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/issues/466
    ///
    func testInsertingNewlineAtTheMiddleOfHeaderDoesNotLooseHeaderStyleOnNewline() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleHeader(.h1, range: .zero)
        textView.insertText("Header Header")

        textView.selectedRange = NSMakeRange("Header".count, 0)
        textView.insertText("\n")

        let identifiers = textView.formattingIdentifiersAtIndex(textView.selectedRange.location)
        XCTAssert(identifiers.contains(.header1))

        XCTAssertEqual(textView.getHTML(prettify: false), "<h1>Header</h1><h1> Header</h1>")
    }


    // MARK: - Unicode tests

    /// Tests that applying bold to a string with unicode characters doesn't crash the app.
    ///
    /// This test was crashing the app as of 2017/04/18.
    ///
    func testBoldWithUnicodeCharacter() {
        let string = "Hello 🌎!"
        let textView = TextViewStub(withHTML: string)
        let swiftRange = NSRange(location: 0, length: string.count)
        let utf16Range = string.utf16NSRange(from: swiftRange)

        textView.toggleBold(range: utf16Range)
    }

    // MARK: - Lists

    /// Verifies that a Text List does not get removed, whenever the user presses backspace
    ///
    /// Input:
    ///     - Ordered List
    ///     - "First Item"
    ///     - Backspace
    ///
    /// Ref. Scenario Mark I on Issue https://github.com/wordpress-mobile/AztecEditor-iOS/pull/425
    ///
    func testListDoesNotGetLostAfterPressingBackspace() {
        let textView = TextViewStub(withHTML: "")


        textView.toggleOrderedList(range: .zero)
        textView.insertText("First Item")
        textView.deleteBackward()

        let formatter = TextListFormatter(style: .ordered)
        let range = textView.storage.rangeOfEntireString
        let present = formatter.present(in: textView.storage, at: range)

        XCTAssertTrue(present)
    }

    /// Verifies that the List gets nuked whenever the only `\n` present in the document is deleted.
    ///
    /// Input:
    ///     - Ordered List
    ///     - Selection of the EOD
    ///     - Backspace
    ///
    /// Ref. Scenario Mark II on Issue https://github.com/wordpress-mobile/AztecEditor-iOS/pull/425
    ///
    func testEmptyListGetsNukedWheneverTheOnlyNewlineCharacterInTheDocumentIsNuked() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleOrderedList(range: .zero)
        textView.selectedRange = textView.text.endOfStringNSRange()
        textView.deleteBackward()

        XCTAssertFalse(TextListFormatter.listsOfAnyKindPresent(in: textView.typingAttributes))
        XCTAssert(textView.storage.length == 0)
    }

    /// Verifies that New Line Characters get effectively inserted after a Text List.
    ///
    /// Input:
    ///     - Ordered List
    ///     - \n at the end of the document
    ///
    /// Ref. Scenario Mark III on Issue https://github.com/wordpress-mobile/AztecEditor-iOS/pull/425
    ///
    func testNewLinesAreInsertedAfterEmptyList() {
        let textView = TextViewStub(withHTML: "")

        // Toggle List + Move the selection to the EOD
        textView.toggleOrderedList(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        // Insert Newline
        var expectedLength = textView.text.count
        textView.insertText(String(.lineFeed))
        expectedLength += String(.lineFeed).count

        XCTAssertEqual(textView.text.count, expectedLength)
    }

    /// Verifies that New List Items do get their bullet, even when the ending `\n` character was deleted.
    ///
    /// Input:
    ///     - Ordered List
    ///     - Text: Constants.sampleText0
    ///     - Selection of the `\n` at the EOD, and backspace
    ///     - Text: "\n"
    ///     - Text: Constants.sampleText1
    ///
    /// Ref. Scenario Mark IV on Issue https://github.com/wordpress-mobile/AztecEditor-iOS/pull/425
    ///
    func testNewLinesGetBulletStyleEvenAfterDeletingEndOfDocumentNewline() {
        let newline = String(.lineFeed)
        let textView = TextViewStub(withHTML: "")

        textView.toggleOrderedList(range: .zero)
        textView.insertText(Constants.sampleText0)

        // Select the end of the document
        textView.selectedRange = textView.text.endOfStringNSRange()

        // Delete + Insert Newline
        textView.deleteBackward()
        textView.insertText(newline + Constants.sampleText1)

        // Verify it's still present
        let secondLineIndex = Constants.sampleText0.count + newline.count
        let secondLineRange = NSRange(location: secondLineIndex, length: Constants.sampleText1.count)

        let formatter = TextListFormatter(style: .ordered)
        let present = formatter.present(in: textView.storage, at: secondLineRange)

        XCTAssert(present)
    }

    /// Verifies that after selecting a newline below a TextList, TextView wil not render (nor carry over)
    /// the Text List formatting attributes.
    ///
    /// Input:
    ///     - Ordered List
    ///     - Selection of the `\n` at the EOD
    ///
    /// Ref. Scenario Mark V on Issue https://github.com/wordpress-mobile/AztecEditor-iOS/pull/425
    ///
    func testTypingAttributesLooseTextListWhenSelectingAnEmptyNewlineBelowTextList() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleOrderedList(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        XCTAssertFalse(TextListFormatter.listsOfAnyKindPresent(in: textView.typingAttributes))
    }

    /// Verifies that a Text List gets removed, whenever the user types `\n` in an empty line.
    ///
    /// Input:
    ///     - Ordered List
    ///     - `\n` on the first line
    ///
    /// Ref. Scenario Mark IV on Issue https://github.com/wordpress-mobile/AztecEditor-iOS/pull/425
    ///
    func testListGetsRemovedWhenTypingNewLineOnAnEmptyBullet() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleOrderedList(range: .zero)
        textView.insertText(String(.lineFeed))

        let formatter = TextListFormatter(style: .ordered)
        let attributedText = textView.attributedText!

        for location in 0 ..< attributedText.length {
            XCTAssertFalse(formatter.present(in: attributedText, at: location))
        }

        XCTAssertFalse(TextListFormatter.listsOfAnyKindPresent(in: textView.typingAttributes))
    }

    /// Verifies that toggling an Unordered List, when editing an empty document, inserts a Newline.
    ///
    /// Input:
    ///     - Unordered List
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/414
    ///
    func testTogglingUnorderedListsOnEmptyDocumentsInsertsNewline() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleUnorderedList(range: .zero)
        XCTAssert(textView.text.isEndOfLine())
    }

    /// Verifies that toggling an Unordered List, when editing the end of a non empty line should
    /// never insert a newline, but that a newline is inserted for an empty line.
    ///
    /// Input:
    ///     - "Something Here"
    ///     - Selection of the end of document
    ///     - Unordered List
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/414
    ///
    func testTogglingUnorderedListsOnNonEmptyDocumentsWhenSelectedRangeIsAtTheEndOfDocumentWillInsertNewline() {
        let textView = TextViewStub(withHTML: Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.toggleUnorderedList(range: .zero)
        XCTAssertEqual(textView.text, Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.insertText(Constants.sampleText1)
        textView.insertText(String(.lineFeed))

        XCTAssertEqual(textView.text, Constants.sampleText0 + Constants.sampleText1 + String(.lineFeed) + String(.lineFeed) )
    }

    /// Verifies that toggling an Ordered List, when editing an empty document, inserts a Newline.
    ///
    /// Input:
    ///     - Ordered List
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/414
    ///
    func testTogglingOrderedListsOnEmptyDocumentsInsertsNewline() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleOrderedList(range: .zero)
        XCTAssert(textView.text.isEndOfLine())
    }

    /// Verifies that toggling an Ordered List, when editing the end of a non empty document, inserts a Newline.
    ///
    /// Input:
    ///     - "Something Here"
    ///     - Selection of the end of document
    ///     - Ordered List
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/414
    ///
    func testTogglingOrderedListsOnNonEmptyDocumentsWhenSelectedRangeIsAtTheEndOfDocumentWillInsertNewline() {
        let textView = TextViewStub(withHTML: Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.toggleOrderedList(range: .zero)
        XCTAssertEqual(textView.text, Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.insertText(Constants.sampleText1)
        textView.insertText(String(.lineFeed))

        let expected = Constants.sampleText0 + Constants.sampleText1 + String(.lineFeed) + String(.lineFeed)
        
        XCTAssertEqual(textView.text, expected)
    }

    /// When deleting the newline between lines 1 and 2 in the following example:
    ///     Line 1: <empty>
    ///     Line 2: <empty> (with list style)
    ///     Line 3: <empty>
    ///
    /// Aztec tends to naturally maintain the list style alive, due to the newline between line 2 and
    /// 3, since line 1 has no paragraph style once its closing newline is removed.
    ///
    /// This test makes sure that removing the newline between line 1 and 2, also removes the list
    /// style in line 2.
    ///
    func testDeleteNewlineRemovesListStyleIfPreceededByAnEmptyLine() {
        let textView = TextViewStub()

        textView.insertText(String(.lineFeed))
        textView.toggleUnorderedList(range: textView.selectedRange)
        textView.deleteBackward()

        XCTAssertFalse(TextListFormatter.listsOfAnyKindPresent(in: textView.typingAttributes))
    }

    /// When the caret is positioned at both EoF and EoL, inserting a line separator (in most
    /// editors by pressing shift + enter) must not remove the list style.
    ///
    /// This test is to avoid regressions on:
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/594
    ///
    func testShiftEnterAtEndOfListAndEndOfFile() {
        let textView = TextViewStub()

        textView.insertText("First line")
        textView.toggleUnorderedList(range: textView.selectedRange)
        textView.insertText(String(.lineSeparator))

        let unorderedListFormatter = TextListFormatter(style: .unordered)

        XCTAssertTrue(unorderedListFormatter.present(in: textView.storage, at: 0))
        XCTAssertTrue(unorderedListFormatter.present(in: textView.storage, at: textView.selectedRange))
    }
    
    /// This test makes sure that lists are ended when the user presses ENTER twice.
    ///
    /// Related issue:
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/1012
    ///
    func testDoubleNewlineEndsList() {
        let textView = TextViewStub()
        let firstLine = "First Line"
        let secondLine = "Second Line"
        
        textView.insertText(firstLine)
        textView.toggleUnorderedList(range: textView.selectedRange)
        textView.insertText(String(.paragraphSeparator))
        textView.insertText(String(.paragraphSeparator))
        textView.insertText(secondLine)
        
        let firstLineParagraphStyle = textView.storage.attributes(at: 0, effectiveRange: nil).paragraphStyle()
        let secondLineParagraphStyle = textView.storage.attributes(at: firstLine.count + 1, effectiveRange: nil).paragraphStyle()
        
        XCTAssertTrue(firstLineParagraphStyle.properties.contains(where: { (property) -> Bool in
            return property is TextList || property is HTMLLi
        }))
        
        XCTAssertFalse(secondLineParagraphStyle.properties.contains(where: { (property) -> Bool in
            return property is TextList || property is HTMLLi
        }))
    }


    // MARK: - Blockquotes

    /// Verifies that a Blockquote does not get removed whenever the user presses backspace
    ///
    /// Input:
    ///     - Blockquote
    ///     - Text: Constants.sampleText0
    ///     - Backspace
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/422
    ///
    func testBlockquoteDoesNotGetLostAfterPressingBackspace() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        textView.insertText(Constants.sampleText0)
        textView.deleteBackward()

        let formatter = BlockquoteFormatter()
        let range = textView.storage.rangeOfEntireString

        XCTAssertTrue(formatter.present(in: textView.storage, at: range))
    }

    /// Verifies that the Blockquote gets nuked whenever the only `\n` present in the document is deleted.
    ///
    /// Input:
    ///     - Blockquote
    ///     - Selection of the EOD
    ///     - Backspace
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/422
    ///
    func testEmptyBlockquoteGetsNukedWheneverTheOnlyNewlineCharacterInTheDocumentIsNuked() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        textView.selectedRange = textView.text.endOfStringNSRange()
        textView.deleteBackward()

        let formatter = BlockquoteFormatter()

        XCTAssertFalse(formatter.present(in: textView.typingAttributes))
        XCTAssert(textView.storage.length == 0)
    }

    /// Verifies that New Line Characters get effectively inserted after a Blockquote.
    ///
    /// Input:
    ///     - Blockquote
    ///     - \n at the end of the document
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/422
    ///
    func testNewLinesAreInsertedAfterEmptyBlockquote() {
        let newline = String(.lineFeed)
        let textView = TextViewStub(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        var expectedLength = textView.text.count
        textView.insertText(newline)
        expectedLength += newline.count

        XCTAssertEqual(textView.text.count, expectedLength)
    }

    /// Verifies that New Blockquote Lines do get their style, even when the ending `\n` character was deleted.
    ///
    /// Input:
    ///     - Blockquote
    ///     - Text: Constants.sampleText0
    ///     - Selection of the `\n` at the EOD, and backspace
    ///     - Text: "\n"
    ///     - Text: Constants.sampleText1
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/422
    ///
    func testNewLinesGetBlockquoteStyleEvenAfterDeletingEndOfDocumentNewline() {
        let newline = String(.lineFeed)

        let textView = TextViewStub(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        textView.insertText(Constants.sampleText0)
        textView.selectedRange = textView.text.endOfStringNSRange()

        // Delete + Insert Newline
        textView.deleteBackward()
        textView.insertText(newline)
        textView.insertText(Constants.sampleText1)

        // Verify it's still present
        let secondLineIndex = Constants.sampleText0.count + newline.count
        let secondLineRange = NSRange(location: secondLineIndex, length: Constants.sampleText1.count)

        let formatter = BlockquoteFormatter()
        let present = formatter.present(in: textView.storage, at: secondLineRange)
        
        XCTAssert(present)
    }

    /// Verifies that after selecting a newline below a Blockquote, TextView wil not render (nor carry over)
    /// the Blockquote formatting attributes.
    ///
    /// Input:
    ///     - Blockquote
    ///     - Selection of the `\n` at the EOD
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/422
    ///
    func testTypingAttributesLooseBlockquoteWhenSelectingAnEmptyNewlineBelowBlockquote() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        XCTAssertFalse(BlockquoteFormatter().present(in: textView.typingAttributes))
    }

    /// Verifies that Blockquotes get removed whenever the user types `\n` in an empty line.
    ///
    /// Input:
    ///     - Ordered List
    ///     - `\n` on the first line
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/422
    ///
    func testBlockquoteGetsRemovedWhenTypingNewLineOnAnEmptyBlockquoteLine() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        textView.insertText(String(.lineFeed))

        let formatter = BlockquoteFormatter()
        let attributedText = textView.attributedText!

        for location in 0 ..< attributedText.length {
            XCTAssertFalse(formatter.present(in: attributedText, at: location))
        }

        XCTAssertFalse(formatter.present(in: textView.typingAttributes))
    }

    /// Verifies that toggling a Blockquote, when editing an empty document, inserts a Newline.
    ///
    /// Input:
    ///     - Blockquote
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/422
    ///
    func testTogglingBlockquoteOnEmptyDocumentsInsertsNewline() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        XCTAssertEqual(textView.text, String(.paragraphSeparator))
    }

    /// Verifies that toggling a Blockquote, when editing the end of a non empty document, inserts a Newline.
    ///
    /// Input:
    ///     - Text: Constants.sampleText0
    ///     - Selection of the end of document
    ///     - Blockquote
    ///     - Backspace
    ///     - Text: Constants.sampleText1
    ///     - Text: newline
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/422
    ///
    func testTogglingBlockquoteOnNonEmptyDocumentsWhenSelectedRangeIsAtTheEndOfDocumentWillInsertNewline() {
        let textView = TextViewStub(withHTML: Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.toggleBlockquote(range: .zero)
        XCTAssertEqual(textView.text, Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.insertText(Constants.sampleText1)
        textView.insertText(String(.lineFeed))

        XCTAssertEqual(textView.text, Constants.sampleText0 + Constants.sampleText1 + String(.lineFeed) + String(.lineFeed))
    }

    /// Verifies that toggling a Blockquote paragraph in the middle of paragraph does not crash system.    
    ///
    func testTogglingBlockquoteOnMiddleOfRangeDoesNotCrash() {
        let initialQuote = """
            <blockquote><strong>Quote One</strong></blockquote>
            <blockquote><strong>Quote Two</strong></blockquote>
            <blockquote><strong>Quote Three</strong></blockquote>
        """
        let textView = TextViewStub(withHTML: initialQuote)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.toggleBlockquote(range: NSRange(location: 11, length: 0))

        XCTAssertEqual(textView.text, "Quote One" + String(.paragraphSeparator)+"Quote Two"+String(.lineFeed)+"Quote Three")
    }


    // MARK: - Pre

    /// Verifies that a Pre does not get removed whenever the user presses backspace
    ///
    /// Input:
    ///     - Pre
    ///     - Text: Constants.sampleText0
    ///     - Backspace
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/420
    ///
    func testPreDoesNotGetLostAfterPressingBackspace() {
        let textView = TextViewStub(withHTML: "")

        textView.togglePre(range: .zero)
        textView.insertText(Constants.sampleText0)
        textView.deleteBackward()

        let formatter = PreFormatter()
        let range = textView.storage.rangeOfEntireString

        XCTAssertTrue(formatter.present(in: textView.storage, at: range))
    }

    /// Verifies that the Pre Style gets nuked whenever the only `\n` present in the document is deleted.
    ///
    /// Input:
    ///     - Pre
    ///     - Selection of the EOD
    ///     - Backspace
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/420
    ///
    func testEmptyPreGetsNukedWheneverTheOnlyNewlineCharacterInTheDocumentIsNuked() {
        let textView = TextViewStub(withHTML: "")

        textView.togglePre(range: .zero)
        textView.selectedRange = textView.text.endOfStringNSRange()
        textView.deleteBackward()

        let formatter = PreFormatter()

        XCTAssertFalse(formatter.present(in: textView.typingAttributes))
        XCTAssert(textView.storage.length == 0)
    }

    /// Verifies that New Line Characters get effectively inserted after a Pre.
    ///
    /// Input:
    ///     - Pre
    ///     - \n at the end of the document
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/420
    ///
    func testNewLinesAreInsertedAfterEmptyPre() {
        let newline = String(.lineFeed)
        let textView = TextViewStub(withHTML: "")

        textView.togglePre(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        var expectedLength = textView.text.count
        textView.insertText(newline)
        expectedLength += newline.count

        XCTAssertEqual(textView.text.count, expectedLength)
    }

    /// Verifies that New Pre Lines do get their style, even when the ending `\n` character was deleted.
    ///
    /// Input:
    ///     - Blockquote
    ///     - Text: Constants.sampleText0
    ///     - Selection of the `\n` at the EOD, and backspace
    ///     - Text: "\n"
    ///     - Text: Constants.sampleText1
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/420
    ///
    func testNewLinesGetPreStyleEvenAfterDeletingEndOfDocumentNewline() {
        let newline = String(.lineFeed)

        let textView = TextViewStub(withHTML: "")

        textView.togglePre(range: .zero)
        textView.insertText(Constants.sampleText0)
        textView.selectedRange = textView.text.endOfStringNSRange()

        // Delete + Insert Newline
        textView.deleteBackward()
        textView.insertText(newline)
        textView.insertText(Constants.sampleText1)

        // Verify it's still present
        let secondLineIndex = Constants.sampleText0.count + newline.count
        let secondLineRange = NSRange(location: secondLineIndex, length: Constants.sampleText1.count)

        let formatter = PreFormatter()
        let present = formatter.present(in: textView.storage, at: secondLineRange)

        XCTAssert(present)
    }

    /// Verifies that after selecting a newline below a Pre, TextView wil not render (nor carry over)
    /// the Pre formatting attributes.
    ///
    /// Input:
    ///     - Pre
    ///     - Selection of the `\n` at the EOD
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/420
    ///
    func testTypingAttributesLoosePreWhenSelectingAnEmptyNewlineBelowPre() {
        let textView = TextViewStub(withHTML: "")

        textView.togglePre(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        XCTAssertFalse(PreFormatter().present(in: textView.typingAttributes))
    }

    /// Verifies that Pre get removed whenever the user types `\n` in an empty line.
    ///
    /// Input:
    ///     - Pre
    ///     - `\n` on the first line
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/420
    ///
    func testPreGetsRemovedWhenTypingNewLineOnAnEmptyPreLine() {
        let textView = TextViewStub(withHTML: "")

        textView.togglePre(range: .zero)
        textView.insertText(String(.lineFeed))

        let formatter = PreFormatter()
        let attributedText = textView.attributedText!

        for location in 0 ..< attributedText.length {
            XCTAssertFalse(formatter.present(in: attributedText, at: location))
        }

        XCTAssertFalse(formatter.present(in: textView.typingAttributes))
    }

    /// Verifies that toggling a Pre, when editing an empty document, inserts a Newline.
    ///
    /// Input:
    ///     - Pre
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/420
    ///
    func testTogglingPreOnEmptyDocumentsInsertsNewline() {
        let textView = TextViewStub(withHTML: "")

        textView.togglePre(range: .zero)
        XCTAssertEqual(textView.text, String(.paragraphSeparator))
    }

    /// Verifies that toggling a Pre, when editing the end of a non empty document, inserts a Newline.
    ///
    /// Input:
    ///     - Text: Constants.sampleText0
    ///     - Selection of the end of document
    ///     - Blockquote
    ///     - Backspace
    ///     - Text: Constants.sampleText1
    ///     - Text: newline
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/420
    ///
    func testTogglingPreOnNonEmptyDocumentsWhenSelectedRangeIsAtTheEndOfDocumentWillInsertNewline() {
        let textView = TextViewStub(withHTML: Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.togglePre(range: .zero)
        XCTAssertEqual(textView.text, Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.insertText(Constants.sampleText1)
        textView.insertText(String(.lineFeed))
        
        XCTAssertEqual(textView.text, Constants.sampleText0 + Constants.sampleText1 + String(.lineFeed) + String(.lineFeed))
    }    

    // MARK: - Media: Images
    
    
    func testPasteImage() {
        let sourceTextView = TextViewStub(withHTML: "<em>This is an image </em>")
        let targetTextView = TextViewStub(withHTML: "<strong>Pasted: </strong>")
        
        let videoInsertionRange = NSRange(location: sourceTextView.text.count, length: 0)
        let _ = sourceTextView.replaceWithImage(at: videoInsertionRange, sourceURL: URL(string: "image.jpg")!, placeHolderImage: nil)
        
        sourceTextView.selectedRange = NSRange(location: 0, length: sourceTextView.text.count)
        sourceTextView.copy(nil)
        
        targetTextView.selectedRange = NSRange(location: targetTextView.text.count, length: 0)
        targetTextView.paste(nil)
        
        XCTAssertEqual(targetTextView.getHTML(), "<p><strong>Pasted: </strong><em>This is an image <img src=\"image.jpg\"></em></p>")
    }
    
    func testPasteImageWithoutFormatting() {
        let sourceTextView = TextViewStub(withHTML: "<em>This is an image </em>")
        let targetTextView = TextViewStub(withHTML: "<strong>Pasted: </strong>")
        
        let videoInsertionRange = NSRange(location: sourceTextView.text.count, length: 0)
        let _ = sourceTextView.replaceWithImage(at: videoInsertionRange, sourceURL: URL(string: "image.jpg")!, placeHolderImage: nil)
        
        sourceTextView.selectedRange = NSRange(location: 0, length: sourceTextView.text.count)
        sourceTextView.copy(nil)
        
        targetTextView.selectedRange = NSRange(location: targetTextView.text.count, length: 0)
        targetTextView.pasteWithoutFormatting(nil)
        
        XCTAssertEqual(targetTextView.getHTML(), "<p><strong>Pasted: This is an image <img src=\"image.jpg\"></strong></p>")
    }
    
    // MARK: - Media: Video

    func testInsertVideo() {
        let textView = TextViewStub()
        let _ = textView.replaceWithVideo(at: NSRange(location:0, length:0), sourceURL: URL(string: "video.mp4")!, posterURL: URL(string: "video.jpg"), placeHolderImage: nil)
        XCTAssertEqual(textView.getHTML(), "<p><video src=\"video.mp4\" poster=\"video.jpg\"></video></p>")
    }
    
    func testPasteVideo() {
        let sourceTextView = TextViewStub(withHTML: "<em>This is a video </em>")
        let targetTextView = TextViewStub(withHTML: "<strong>Pasted: </strong>")
        
        let videoInsertionRange = NSRange(location: sourceTextView.text.count, length: 0)
        let _ = sourceTextView.replaceWithVideo(at: videoInsertionRange, sourceURL: URL(string: "video.mp4")!, posterURL: URL(string: "video.jpg"), placeHolderImage: nil)
        
        sourceTextView.selectedRange = NSRange(location: 0, length: sourceTextView.text.count)
        sourceTextView.copy(nil)
        
        targetTextView.selectedRange = NSRange(location: targetTextView.text.count, length: 0)
        targetTextView.paste(nil)
        
        XCTAssertEqual(targetTextView.getHTML(), "<p><strong>Pasted: </strong><em>This is a video <video src=\"video.mp4\" poster=\"video.jpg\"></video></em></p>")
    }
    
    func testPasteVideoWithoutFormatting() {
        let sourceTextView = TextViewStub(withHTML: "<em>This is a video </em>")
        let targetTextView = TextViewStub(withHTML: "<strong>Pasted: </strong>")
        
        let videoInsertionRange = NSRange(location: sourceTextView.text.count, length: 0)
        let _ = sourceTextView.replaceWithVideo(at: videoInsertionRange, sourceURL: URL(string: "video.mp4")!, posterURL: URL(string: "video.jpg"), placeHolderImage: nil)
        
        sourceTextView.selectedRange = NSRange(location: 0, length: sourceTextView.text.count)
        sourceTextView.copy(nil)
        
        targetTextView.selectedRange = NSRange(location: targetTextView.text.count, length: 0)
        targetTextView.pasteWithoutFormatting(nil)
        
        XCTAssertEqual(targetTextView.getHTML(), "<p><strong>Pasted: This is a video <video src=\"video.mp4\" poster=\"video.jpg\"></video></strong></p>")
    }

    /// Verifies that any edition performed on VideoAttachment's srcURL attribute is properly serialized back,
    /// during the HTML generation step.
    ///
    func testEditingVideoAttachmentAttributesCausesAttributesToProperlySerializeBack() {
        let textView = TextViewStub(withHTML: "<video src=\"video.mp4\" poster=\"video.jpg\" alt=\"The video\"></video>")
        guard let videoAttachment = textView.storage.mediaAttachments.first! as? VideoAttachment else {
            fatalError()
        }

        videoAttachment.updateURL(URL(string:"newVideo.mp4")!)
        textView.refresh(videoAttachment)

        XCTAssertEqual(textView.getHTML(), "<p><video src=\"newVideo.mp4\" poster=\"video.jpg\" alt=\"The video\"></video></p>")
    }

    func testParseVideoWithExtraAttributes() {
        let videoHTML = "<video src=\"newVideo.mp4\" poster=\"video.jpg\" data-wpvideopress=\"videopress\"></video>"
        let textView = TextViewStub(withHTML: videoHTML)

        XCTAssertEqual(textView.getHTML(), "<p><video src=\"newVideo.mp4\" poster=\"video.jpg\" data-wpvideopress=\"videopress\"></video></p>")

        guard let attachment = textView.storage.mediaAttachments.first as? VideoAttachment else {
            XCTFail("An video attachment should be present")
            return
        }
        XCTAssertEqual(attachment.extraAttributes["data-wpvideopress"], .string("videopress"), "Property should be available")

        attachment.extraAttributes["data-wpvideopress"] = .string("ABCDE")

        XCTAssertEqual(textView.getHTML(), "<p><video src=\"newVideo.mp4\" poster=\"video.jpg\" data-wpvideopress=\"ABCDE\"></video></p>")
    }

    func testParseVideoWithSourceElements() {
        let videoHTML = "<video poster=\"video.jpg\"><source src=\"newVideo.mp4\"></video>"
        let textView = TextViewStub(withHTML: videoHTML)

        XCTAssertEqual(textView.getHTML(), "<p><video poster=\"video.jpg\"><source src=\"newVideo.mp4\"></video></p>")

        guard let attachment = textView.storage.mediaAttachments.first as? VideoAttachment else {
            XCTFail("An video attachment should be present")
            return
        }
        XCTAssertEqual(attachment.sources.count, 1, "One source should be available")

        XCTAssertEqual(attachment.sources[0].src, "newVideo.mp4", "Video source should match")

        XCTAssertEqual(attachment.mediaURL, URL(string:"newVideo.mp4"), "Video source should match")
    }
    // MARK: - Comments

    /// This test check if the insertion of a Comment Attachment works correctly and the expected tag gets inserted
    ///
    func testInsertComment() {
        let textView = TextViewStub()

        textView.replace(.zero, withComment: "more")
        let html = textView.getHTML()

        XCTAssertEqual(html, "<p><!--more--></p>")
    }

    /// This test check if the insertion of a Comment Attachment works correctly and the expected tag gets inserted
    ///
    func testInsertCommentAttachmentDoNotCrashTheEditorWhenCalledSequentially() {
        let textView = TextViewStub()
        textView.replace(.zero, withComment: "more")
        textView.replace(.zero, withComment: "some other comment should go here")

        let html = textView.getHTML()

        XCTAssertEqual(html, "<p><!--some other comment should go here--><!--more--></p>")
    }


    // MARK: - HR

    /// This test check if the insertion of an horizontal ruler works correctly and the hr tag is inserted
    ///
    func testReplaceRangeWithHorizontalRuler() {
        let textView = TextViewStub()

        textView.replaceWithHorizontalRuler(at: .zero)
        let html = textView.getHTML(prettify: false)

        XCTAssertEqual(html, "<p><hr></p>")
    }

    /// This test check if the insertion of antwo horizontal ruler works correctly and the hr tag(s) are inserted
    ///
    func testReplaceRangeWithHorizontalRulerGeneratesExpectedHTMLWhenExecutedSequentially() {
        let textView = TextViewStub()

        textView.replaceWithHorizontalRuler(at: .zero)
        textView.replaceWithHorizontalRuler(at: .zero)
        let html = textView.getHTML(prettify: false)

        XCTAssertEqual(html, "<p><hr><hr></p>")
    }

    /// This test check if the insertion of an horizontal ruler over an image attachment works correctly and the hr tag is inserted
    ///
    func testReplaceRangeWithHorizontalRulerRulerOverImage() {
        let textView = TextViewStub()

        textView.replaceWithImage(at: .zero, sourceURL: URL(string:"https://wordpress.com")!, placeHolderImage: nil)
        textView.replaceWithHorizontalRuler(at: NSRange(location: 0, length:1))

        let html = textView.getHTML(prettify: false)
        
        XCTAssertEqual(html, "<p><hr></p>")
    }

    func testReplaceRangeWithAttachmentDontDisableDefaultParagraph() {
        let textView = TextViewStub()

        textView.replaceWithImage(at: .zero, sourceURL: URL(string:"https://wordpress.com")!, placeHolderImage: nil)

        let html = textView.getHTML()

        XCTAssertEqual(html, "<p><img src=\"https://wordpress.com\"></p>")

        textView.selectedRange = NSRange(location: NSAttributedString.lengthOfTextAttachment, length: 1)
        guard let font = textView.typingAttributes[.font] as? UIFont else {
            XCTFail("Font should be set")
            return
        }
        XCTAssertEqual(font, textView.defaultFont)
    }

    func testInsertEmojiKeepsDefaultFont() {
        let font = UIFont(name:"HelveticaNeue", size: 14)!
        let textView = TextViewStub(font: font)

        textView.insertText("😘")
        let currentTypingFont = textView.typingAttributes[.font] as! UIFont
        XCTAssertEqual(currentTypingFont.fontDescriptor, font.fontDescriptor, "Font should be set to default")
    }



    func testRemovalOfAttachment() {
        let textView = TextViewStub()

        let attachment = textView.replaceWithImage(at: .zero, sourceURL: URL(string:"https://wordpress.com")!, placeHolderImage: nil)

        var html = textView.getHTML()

        XCTAssertEqual(html, "<p><img src=\"https://wordpress.com\"></p>")

        textView.remove(attachmentID: attachment.identifier)

        html = textView.getHTML()

        XCTAssertEqual(html, "")
    }

    /// This method test the parsing of img tag that contains attributes thar are not directly supported by Image attachments
    /// It also tests if changes on those attributes is correctly reflected on the generated HTML
    ///
    func testParseImageWithExtraAttributes() {
        let html = "<img src=\"image.jpg\" class=\"alignnone\" alt=\"Alt\" title=\"Title\">"
        let textView = TextViewStub(withHTML: html)

        XCTAssertEqual(textView.getHTML(), "<p><img src=\"image.jpg\" class=\"alignnone\" alt=\"Alt\" title=\"Title\"></p>")

        guard let attachment = textView.storage.mediaAttachments.first as? ImageAttachment else {
            XCTFail("An video attachment should be present")
            return
        }
        XCTAssertEqual(attachment.extraAttributes["alt"], .string("Alt"), "Alt Property should be available")
        XCTAssertEqual(attachment.extraAttributes["title"], .string("Title"), "Title Property should be available")

        attachment.extraAttributes["alt"] = .string("Changed Alt")
        attachment.extraAttributes["class"] = .string("wp-image-169")

        XCTAssertEqual(textView.getHTML(), "<p><img src=\"image.jpg\" class=\"alignnone wp-image-169\" alt=\"Changed Alt\" title=\"Title\"></p>")
    }


    // MARK: - Bugfixing

    /// This test verifies that the H1 Header does not get lost during the Rich <> Raw transitioning.
    ///
    func testToggleHtmlWithTwoEmptyLineBreaksDoesNotLooseHeaderStyle() {
        let pristineHTML = "<br><br><h1>Header</h1>"
        let textView = TextViewStub(withHTML: pristineHTML)
        let generatedHTML = textView.getHTML(prettify: false)

        XCTAssertEqual(generatedHTML, "<p><br><br></p><h1>Header</h1>")
    }

    /// This test verifies that the H1 Header does not get lost, in the scenario in which the H1 is contained
    /// within the second line of text (and thus, would be expected to get rendered below!).
    ///
    func testToggleHtmlWithTwoLineBreaksAndInlineHeaderDoesNotLooseHeaderStyle() {
        let pristineHTML = "<br>1<br>2<h1>Heder</h1>"
        let textView = TextViewStub(withHTML: pristineHTML)
        let generatedHTML = textView.getHTML(prettify: false)

        XCTAssertEqual(generatedHTML, "<p><br>1<br>2</p><h1>Heder</h1>")
    }

    /// This test verifies that img class attributes are not duplicated
    ///
    func testParseImageDoesntDuplicateExtraAttributes() {
        let html = "<img src=\"image.jpg\" class=\"alignnone wp-image-test\" title=\"Title\" alt=\"Alt\">"
        let textView = TextViewStub(withHTML: html)
        let generatedHTML = textView.getHTML()

        XCTAssertEqual(generatedHTML, "<p>\(html)</p>")
    }

    /// This test verifies that copying the Sample HTML Document does not trigger a crash.
    /// Ref. Issue #626: NSKeyedArchiver Crash
    ///
    func testCopyDoesNotCauseAztecToCrash() {
        let textView = TextViewStub(withSampleHTML: true)
        textView.selectedRange = textView.storage.rangeOfEntireString
        textView.copy(nil)
    }

    /// This test verifies that cutting the Sample HTML Document does not trigger a crash.
    /// Ref. Issue #626: NSKeyedArchiver Crash
    ///
    func testCutDoesNotCauseAztecToCrash() {
        let textView = TextViewStub(withSampleHTML: true)
        textView.selectedRange = textView.storage.rangeOfEntireString
        textView.cut(nil)
    }

    /// This test verifies that trying to store data in an empty pasteboard
    /// doesn't cause Aztec to crash.
    ///
    func testWritingIntoAnEmptyPasteboardDoesNotCauseAztecToCrash() {
        UIPasteboard.forTesting.reset()

        let data = "Foo".data(using: .utf8)!
        let textView = TextViewStub(withSampleHTML: true)
        textView.storeInPasteboard(encoded: data)

        XCTAssertEqual(UIPasteboard.forTesting.items.count, 1)
    }

    /// This test verifies that Japanese Characters do not get hexa encoded anymore, since we actually support UTF8!
    /// Ref. Issue #632: Stop encoding non-latin characters
    ///
    func testJapaneseCharactersWillNotGetEscaped() {
        let pristineJapanese = "国ドぼゆ九会以つまにの市賛済ツ聞数ナシ私35奨9企め全談ヱマヨワ全竹スレフヨ積済イナ続害ホテ" +
            "ソト聞長津装げ。16北夢みは殻容ク洋意能緯ざた投記ぐだもみ学徳局みそイし済更離ラレミネ展至察畑しのわぴ。航リむは" +
            "素希ホソ元不サト国十リ産望イげ地年ニヲネ将広ぴん器学サナチ者一か新米だしず災9識じざい総台男みのちフ。"

        let textView = TextViewStub(withHTML: pristineJapanese)
        XCTAssertEqual(textView.getHTML(), "<p>\(pristineJapanese)</p>")
    }

    /// This test verifies that Nested Text Lists are 'Grouped Together', and not simply appended at the end of
    /// the Properties collection. For instance, a 'broken' behavior would produce the following HTML:
    ///
    ///     <ol><li><blockquote><ol><li><ol><li>First Item</li></ol></li></ol></blockquote></li></ol>
    ///
    /// Ref. Issue #633: Hitting Tab causes the bullet to indent, but the blockquote is not moving
    ///
    func testNestedTextListsAreProperlyGroupedTogether() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleOrderedList(range: .zero)
        textView.toggleBlockquote(range: .zero)
        textView.insertText("First Item")

        // Simulate TAB Event
        let command = textView.keyCommands?.first { command in
            return command.input == String(.tab) && command.modifierFlags.isEmpty
        }

        guard let tab = command else {
            XCTFail()
            return
        }

        // Insert Two Nested Levels
        textView.handleTab(command: tab)
        textView.handleTab(command: tab)

        // Verify!
        let expected = "<ol><li><ol><li><ol><li><blockquote>First Item</blockquote></li></ol></li></ol></li></ol>"
        XCTAssertEqual(textView.getHTML(prettify: false), expected)
    }

    /// This test verifies that the `deleteBackward` call does not result in loosing the Typing Attributes.
    /// Precisely, we'll ensure that the Italics style isn't lost after hitting backspace, and retyping the
    /// deleted character.
    ///
    /// Ref. Issue #749: Loosing Style after hitting Backspace
    ///
    func testDeleteBackwardsDoesNotEndUpLoosingItalicsStyle() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleBoldface(self)
        textView.insertText("First Line")
        textView.insertText("\n")

        textView.toggleItalics(self)
        textView.insertText("Second")

        let expectedHTML = textView.getHTML()
        textView.deleteBackward()
        textView.insertText("d")

        XCTAssertEqual(textView.getHTML(), expectedHTML)
    }

    /// This test verifies that the *ACTUAL* Typing Attributes are retrieved whenever requested from within
    /// UITextView's `onDidChange` delegate callback.
    ///
    /// We're doing this because of (multiple) iOS 11 bugs in which Typing Attributes get lost.
    ///
    /// Ref. Issue #748: Format Bar: Active Style gets de-higlighted
    ///
    func testActiveStyleDoesNotGetLostWheneverOnDidChangeDelegateMethodIsCalled() {
        let textView = TextViewStub(withHTML: "")

        let delegate = TextViewStubDelegate()
        textView.delegate = delegate

        textView.toggleBoldface(self)
        textView.insertText("Bold")
        textView.insertText("\n")

        textView.toggleItalics(self)

        delegate.onDidChange = {
            let identifiers = textView.formattingIdentifiersForTypingAttributes()

            XCTAssert(identifiers.contains(.bold))
            XCTAssert(identifiers.contains(.italic))
        }

        textView.insertText("Italics")
    }

    /// This test verifies that H1 Style doesn't turn rogue, and come back after editing a line of text that
    /// never had H1 style, to begin with!.
    ///
    /// Ref. Issue #747: Zombie H1 Style
    ///
    func testHeaderStyleDoesNotComeBackFromNonExistanceWheneverDeleteBackwardResultsInEmptyParagraph() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleHeader(.h1, range: textView.selectedRange)
        textView.insertText("Header")
        textView.insertText("\n")

        textView.insertText("One Two")
        textView.insertText("\n")

        textView.insertText("T")
        textView.deleteBackward()

        textView.insertText("Three")

        let expected = "<h1>Header</h1><p>One Two</p><p>Three</p>"
        XCTAssertEqual(textView.getHTML(prettify: false), expected)
    }

    /// This test verifies that H1 Style doesn't turn rogue (Scenario #2), and come back after editing a line
    /// of text that never had H1 style, to begin with!.
    ///
    /// Ref. Issue #747: Zombie H1 Style
    ///
    func testHeaderStyleDoesNotComeBackFromNonExistanceWheneverDeleteBackwardResultsInEmptyParagraphBeforeHeaderStyle() {
        let textView = TextViewStub(withHTML: "")

        textView.toggleHeader(.h1, range: textView.selectedRange)
        textView.insertText("Header")
        textView.insertText("\n")

        textView.insertText("1")
        textView.deleteBackward()

        textView.insertText("1")

        let expected = "<h1>Header</h1><p>1</p>"
        XCTAssertEqual(textView.getHTML(prettify: false), expected)
    }

    /// This test verifies that attributes on media attachment are being removed properly.
    /// of text that never had H1 style, to begin with!.
    ///
    func testAttributesOnMediaAttachmentsAreRemoved() {
        let textView = TextViewStub(withHTML: "<img src=\"http://placeholder\" data-wp_upload_id=\"ABCDE\" >")

        guard let attachment = textView.storage.mediaAttachments.first else {
            XCTFail("There must be an attachment")
            return
        }

        guard let attributedValue = attachment.extraAttributes["data-wp_upload_id"] else {
            XCTFail("There must be an attribute with the name data-wp_upload_i")
            return
        }

        XCTAssertEqual(attributedValue, .string("ABCDE"))

        // Remove attribute
        attachment.extraAttributes["data-wp_upload_id"] = nil

        let html = textView.getHTML()

        XCTAssertEqual(html, "<p><img src=\"http://placeholder\"></p>" )
    }

    /// This test makes sure that if an `<hr>` was in the original HTML, it will still get output after our processing.
    func testHRPeristsAfterAztec() {
        let textView = TextViewStub(withHTML: "<h1>Header</h1><p>test<hr></p>")

        let html = textView.getHTML(prettify: false)

        XCTAssertEqual(html, "<h1>Header</h1><p>test</p><p><hr></p>")
    }

    /// This test makes sure that if an auto replacement is made with smaller text, for example an emoji, things work correctly
    func testAutoCompletionReplacementHackWhenUsingEmoji() {
        let textView = TextViewStub(withHTML: "Love")
        let uiTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)!
        
        textView.replace(uiTextRange, withText: "😘")
        
        let html = textView.getHTML()

        XCTAssertEqual(html, "<p>😘</p>")
    }

    func testMultipleFigureCaptionAreProperlyParsed() {
        let originalHTML = """
<figure><img src=\"a.png\" class=\"alignnone\"><figcaption>caption a</figcaption></figure><figure><img src=\"b.png\" class=\"alignnone\"><figcaption>caption b</figcaption></figure>
"""
        let textView = TextViewStub(withHTML: originalHTML)

        XCTAssertEqual(textView.getHTML(prettify: false), originalHTML)
    }

    func testPasteOfURLsWithoutSelectedRange() {
        let textView = TextViewStub(withHTML: "")

        let url = URL(string: "http://wordpress.com")!
        UIPasteboard.forTesting.setValue(url, forPasteboardType: String(kUTTypeURL))

        textView.paste(nil)

        let html = "<p><a href=\"http://wordpress.com\">http://wordpress.com</a></p>"
        XCTAssertEqual(textView.getHTML(prettify: false), html)
    }

    func testPasteOfURLsWithSelectedRange() {
        let textView = TextViewStub(withHTML: "WordPress")

        let url = URL(string: "http://wordpress.com")!
        UIPasteboard.forTesting.setValue(url, forPasteboardType: String(kUTTypeURL))
        textView.selectedRange = NSRange(location: 0, length: 9)
        textView.paste(nil)

        let html = "<p><a href=\"http://wordpress.com\">WordPress</a></p>"
        XCTAssertEqual(textView.getHTML(prettify: false), html)
    }
    
    // MARK: - Non-breaking spaces.
    
    func testNonBreakingSpacesAreProperlyEncoded() {
        let textView = TextViewStub(withHTML: "WordPress")
        
        let html = "<p>&nbsp;&nbsp;</p><p>&nbsp;<br>&nbsp;</p>"
        let expected = "<p>&nbsp;&nbsp;</p><p>&nbsp;<br>&nbsp;</p>"
        
        textView.setHTML(html)
        let output = textView.getHTML(prettify: false)
        
        XCTAssertEqual(output, expected)
    }

    /// This test makes sure that if an empty list is in the original HTML, it will still get output after our processing.
    func testEmptyListsPersistsAfterAztec() {
        let textView = TextViewStub(withHTML: "<ul><li></li></ul>")

        let html = textView.getHTML(prettify: false)

        XCTAssertEqual(html, "<ul><li></li></ul>")
    }

    func testNestedLists() {
        let textView = TextViewStub(withHTML: "WordPress")

        let html = "<ul><li>Hello</li><li>world<ul><li>Inner</li><li>Inner<ul><li>Inner2</li><li>Inner2</li></ul></li></ul></li></ul>"
        let expected = "<ul><li>Hello</li><li>world<ul><li>Inner</li><li>Inner<ul><li>Inner2</li><li>Inner2</li></ul></li></ul></li></ul>"

        textView.setHTML(html)
        let output = textView.getHTML(prettify: false)

        XCTAssertEqual(output, expected)
    }

    // MARK: - Copy/Paste tests

    func testCopyAndPasteToPlainText() {
        let sourceTextView = TextViewStub(withHTML: "This is text with attributes: <strong>bold</strong>")

        sourceTextView.selectedRange = NSRange(location: 0, length: sourceTextView.text.count)
        sourceTextView.copy(nil)

        XCTAssertEqual(UIPasteboard.forTesting.string, "This is text with attributes: bold")
    }

    func testCopyHTML() throws {
        let sourceTextView = TextViewStub(withHTML: "<p>This is text with attributes: <strong>bold</strong> and <italic>italic</italic></p>")

        sourceTextView.selectedRange = NSRange(location: 0, length: sourceTextView.text.count)
        sourceTextView.copy(nil)

        XCTAssertEqual(UIPasteboard.forTesting.html(), "<p>This is text with attributes: <strong>bold</strong> and <italic>italic</italic></p>")
    }

    func testCutHTML() {
        let sourceTextView = TextViewStub(withHTML: "<p>This is text with attributes: <strong>bold</strong> and <italic>italic</italic></p>")

        sourceTextView.selectedRange = NSRange(location: 0, length: sourceTextView.text.count)
        sourceTextView.cut(nil)

        XCTAssertEqual(UIPasteboard.forTesting.html(), "<p>This is text with attributes: <strong>bold</strong> and <italic>italic</italic></p>")
    }

    func testCopyPartialHTML() {
        let sourceTextView = TextViewStub(withHTML: "<p><strong>bold</strong> and <italic>italic</italic></p>")

        sourceTextView.selectedRange = NSRange(location: 0, length: 3)
        sourceTextView.copy(nil)

        XCTAssertEqual(UIPasteboard.forTesting.html(), "<p><strong>bol</strong></p>")
    }

    /// Check if pasting attributed text without color, the color is set to default color
    func testPasteAttributedText() {
        let sourceAttributedText = NSAttributedString(string: "Hello world")
        var pasteItems = [String:Any]()
        pasteItems[kUTTypePlainText as String] = try! sourceAttributedText.data(from: sourceAttributedText.rangeOfEntireString, documentAttributes: [.documentType: DocumentType.plain])
        UIPasteboard.forTesting.setItems([pasteItems], options: [:])
        let textView = TextViewStub(withHTML: "")
        textView.textColor = UIColor.red
        textView.paste(nil)

        let attributedString = textView.attributedText!

        let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
        if let colorSet = attributes[.foregroundColor] as? UIColor {
            XCTAssertEqual(colorSet, UIColor.red)
        }
        XCTAssertEqual(textView.text, "Hello world")
    }

    /// Check that deleting all text resets the typying attributes to the default attributes
    func testDeleteAllTextSetTypyingAttributesToDefault() {
        let textView = TextViewStub(withHTML: "<p style=\"color:0xFF0000\">Hello world</p>")
        textView.defaultTextColor = UIColor.green
        textView.selectedRange = textView.attributedText!.rangeOfEntireString
        textView.deleteBackward()
        let attributes = textView.typingAttributes
        XCTAssertEqual(attributes[.foregroundColor] as! UIColor,UIColor.green)
    }

    func testLinksWithMultipleCharactersNonLatinDontBreak() {
        let textView = TextViewStub(withHTML: "<p><a href=\"www.worpdress.com\">WordPress 워드 프레스</a></p>")
        let html = textView.getHTML()
        XCTAssertEqual(html, "<p><a href=\"www.worpdress.com\">WordPress 워드 프레스</a></p>")

        textView.setHTML("<p><a href=\"www.worpdress.com\">WordPress</a><a href=\"www.jetpack.com\">워드 프레스</a></p>")
        let htmlTwoLinks = textView.getHTML()
        XCTAssertEqual(htmlTwoLinks, "<p><a href=\"www.worpdress.com\">WordPress</a><a href=\"www.jetpack.com\">워드 프레스</a></p>")
    }

}
