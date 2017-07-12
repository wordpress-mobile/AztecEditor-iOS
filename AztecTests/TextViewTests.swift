import XCTest
@testable import Aztec

class TextViewTests: XCTestCase {

    struct Constants {
        static let sampleText0 = "Lorem ipsum sarasum naradum taradum insumun"
        static let sampleText1 = " patronum sitanum elanum zoipancoiamum."
    }

    let attachmentDelegate = TextViewStubAttachmentDelegate()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    // MARK: - TextView construction

    func createEmptyTextView() -> Aztec.TextView {
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())
        richTextView.textAttachmentDelegate = attachmentDelegate
        richTextView.registerAttachmentImageProvider(attachmentDelegate)
        return richTextView
    }

    func createTextView(withHTML html: String) -> Aztec.TextView {
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())
        richTextView.textAttachmentDelegate = attachmentDelegate
        richTextView.setHTML(html)

        return richTextView
    }

    let nonStandardSystemFont = UIFont(name:"HelveticaNeue", size: 14)!

    func createEmptyTextViewWithNonStandardSystemFont() -> Aztec.TextView {
        let richTextView = Aztec.TextView(defaultFont: nonStandardSystemFont, defaultMissingImage: UIImage())
        richTextView.textAttachmentDelegate = attachmentDelegate
        richTextView.registerAttachmentImageProvider(attachmentDelegate)
        return richTextView
    }

    func createTextViewWithContent() -> Aztec.TextView {
        let paragraph = "Lorem ipsum dolar sit amet.\n"
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())
        richTextView.textAttachmentDelegate = attachmentDelegate
        let attributes = [NSParagraphStyleAttributeName : NSParagraphStyle()]
        let templateString = NSMutableAttributedString(string: paragraph, attributes: attributes)

        let attrStr = NSMutableAttributedString()
        attrStr.append(templateString)
        attrStr.append(templateString)
        attrStr.append(templateString)
        richTextView.attributedText = attrStr
        
        return richTextView
    }

    // Confirm the composed textView is property configured.

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

        let count = textView.text!.characters.count
        let maxIndex = count - 1

        // Test upper and lower bounds
        XCTAssert(maxIndex == textView.maxIndex(100))
        XCTAssert(0 == textView.maxIndex(0))
    }

    func testAdjustedIndex() {
        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())

        textView.text = "foobarbaz"

        let count = textView.text!.characters.count
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

    func testFormatIdentifiersSpanningRange() {
        let textView = createTextView(withHTML: "foo<b>bar</b>baz")

        let range = NSRange(location: 3, length: 3)
        let identifiers = textView.formatIdentifiersSpanningRange(range)

        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)
    }

    func testFormatIdentifiersAtIndex() {
        let textView = createTextView(withHTML: "foo<b>bar</b>baz")

        var identifiers = textView.formatIdentifiersAtIndex(4)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)

        identifiers = textView.formatIdentifiersAtIndex(5)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)

        identifiers = textView.formatIdentifiersAtIndex(6)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)


        identifiers = textView.formatIdentifiersAtIndex(0)
        XCTAssert(identifiers.count == 0)

        identifiers = textView.formatIdentifiersAtIndex(3)
        XCTAssert(identifiers.count == 0)

        identifiers = textView.formatIdentifiersAtIndex(7)
        XCTAssert(identifiers.count == 0)
    }


    // MARK: - Toggle Attributes

    func testToggleBold() {
        let textView = createTextView(withHTML: "foo<b>bar</b>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.bold))

        textView.toggleBold(range: range)

        XCTAssert(!textView.formatIdentifiersSpanningRange(range).contains(.bold))

        textView.toggleBold(range: range)

        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.bold))
    }

    func testToggleItalic() {
        let textView = createTextView(withHTML: "foo<i>bar</i>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.italic))

        textView.toggleItalic(range: range)

        XCTAssert(!textView.formatIdentifiersSpanningRange(range).contains(.italic))

        textView.toggleItalic(range: range)

        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.italic))
    }

    func testToggleUnderline() {
        let textView = createTextView(withHTML: "foo<u>bar</u>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.underline))

        textView.toggleUnderline(range: range)

        XCTAssert(!textView.formatIdentifiersSpanningRange(range).contains(.underline))

        textView.toggleUnderline(range: range)

        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.underline))
    }

    func testToggleStrike() {
        let textView = createTextView(withHTML: "foo<strike>bar</strike>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.strikethrough))

        textView.toggleStrikethrough(range: range)

        XCTAssert(!textView.formatIdentifiersSpanningRange(range).contains(.strikethrough))

        textView.toggleStrikethrough(range: range)

        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.strikethrough))
    }

    func testToggleBlockquote() {
        let textView = createTextViewWithContent()
        let length = textView.text.characters.count
        let range = NSRange(location: 0, length: length)

        textView.toggleBlockquote(range: range)

        XCTAssert(textView.formatIdentifiersAtIndex(1).contains(.blockquote))
        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.blockquote))

        textView.toggleBlockquote(range: range)

        XCTAssert(!textView.formatIdentifiersAtIndex(1).contains(.blockquote))
        XCTAssert(!textView.formatIdentifiersSpanningRange(range).contains(.blockquote))
    }

    func testToggleOrderedList() {
        let textView = createTextViewWithContent()
        let length = textView.text.characters.count
        let range = NSRange(location: 0, length: length)

        textView.toggleOrderedList(range: range)

        XCTAssert(textView.formatIdentifiersAtIndex(0).contains(.orderedlist))
        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.orderedlist))

        textView.toggleOrderedList(range: range)

        XCTAssert(!textView.formatIdentifiersAtIndex(0).contains(.orderedlist))
        XCTAssert(!textView.formatIdentifiersSpanningRange(range).contains(.orderedlist))
    }

    func testToggleUnorderedList() {
        let textView = createTextViewWithContent()
        let length = textView.text.characters.count
        let range = NSRange(location: 0, length: length)

        textView.toggleUnorderedList(range: range)

        XCTAssert(textView.formatIdentifiersAtIndex(0).contains(.unorderedlist))
        XCTAssert(textView.formatIdentifiersSpanningRange(range).contains(.unorderedlist))

        textView.toggleOrderedList(range: range)

        XCTAssert(!textView.formatIdentifiersAtIndex(0).contains(.unorderedlist))
        XCTAssert(!textView.formatIdentifiersSpanningRange(range).contains(.unorderedlist))
    }

    /// This test was created to prevent regressions related to this issue:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/350
    ///
    func testToggleBlockquoteAndStrikethrough() {
        let textView = createEmptyTextView()

        textView.toggleStrikethrough(range: NSRange.zero)
        textView.toggleBlockquote(range: NSRange.zero)

        // The test not crashing would be successful.
    }


    // MARK: - Test Attributes Exist

    func check(textView: TextView, range:NSRange, forIndentifier identifier: FormattingIdentifier) -> Bool {
        return textView.formatIdentifiersSpanningRange(range).contains(identifier)
    }

    func testBoldSpansRange() {
        let textView = createTextView(withHTML: "foo<b>bar</b>baz")

        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.bold))
        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.bold))
        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.bold))

        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.bold))
        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.bold))
    }

    func testItalicSpansRange() {
        let textView = createTextView(withHTML: "foo<i>bar</i>baz")

        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.italic))
        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.italic))
        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.italic))

        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.italic))
        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.italic))
    }

    func testUnderlineSpansRange() {
        let textView = createTextView(withHTML: "foo<u>bar</u>baz")

        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.underline))
        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.underline))
        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.underline))

        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.underline))
        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.underline))
    }

    func testStrikethroughSpansRange() {
        let textView = createTextView(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.strikethrough))
        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.strikethrough))
        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.strikethrough))

        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.strikethrough))
        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.strikethrough))
    }

    func testBlockquoteSpansRange() {
        let textView = createTextViewWithContent()
        let range = NSRange(location: 0, length: 1)
        let length = "Lorem ipsum dolar sit amet.\n".characters.count

        textView.toggleBlockquote(range: range)

        XCTAssert(textView.formatIdentifiersSpanningRange(NSRange(location: 0, length: length)).contains(.blockquote))
        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 0, length: length + 1)).contains(.blockquote))
        XCTAssert(!textView.formatIdentifiersSpanningRange(NSRange(location: 1, length: length)).contains(.blockquote))
    }

    func testBoldAtIndex() {
        let textView = createTextView(withHTML: "foo<b>bar</b>baz")

        XCTAssert(textView.formatIdentifiersAtIndex(4).contains(.bold))
        XCTAssert(textView.formatIdentifiersAtIndex(5).contains(.bold))
        XCTAssert(textView.formatIdentifiersAtIndex(6).contains(.bold))

        XCTAssert(!textView.formatIdentifiersAtIndex(2).contains(.bold))
        XCTAssert(!textView.formatIdentifiersAtIndex(7).contains(.bold))
    }

    func testItalicAtIndex() {
        let textView = createTextView(withHTML: "foo<i>bar</i>baz")

        XCTAssert(textView.formatIdentifiersAtIndex(4).contains(.italic))
        XCTAssert(textView.formatIdentifiersAtIndex(5).contains(.italic))
        XCTAssert(textView.formatIdentifiersAtIndex(6).contains(.italic))

        XCTAssert(!textView.formatIdentifiersAtIndex(2).contains(.italic))
        XCTAssert(!textView.formatIdentifiersAtIndex(7).contains(.italic))
    }

    func testUnderlineAtIndex() {
        let textView = createTextView(withHTML: "foo<u>bar</u>baz")

        XCTAssert(textView.formatIdentifiersAtIndex(4).contains(.underline))
        XCTAssert(textView.formatIdentifiersAtIndex(5).contains(.underline))
        XCTAssert(textView.formatIdentifiersAtIndex(6).contains(.underline))

        XCTAssert(!textView.formatIdentifiersAtIndex(2).contains(.underline))
        XCTAssert(!textView.formatIdentifiersAtIndex(7).contains(.underline))
    }

    func testStrikethroughAtIndex() {
        let textView = createTextView(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(textView.formatIdentifiersAtIndex(4).contains(.strikethrough))
        XCTAssert(textView.formatIdentifiersAtIndex(5).contains(.strikethrough))
        XCTAssert(textView.formatIdentifiersAtIndex(6).contains(.strikethrough))

        XCTAssert(!textView.formatIdentifiersAtIndex(2).contains(.strikethrough))
        XCTAssert(!textView.formatIdentifiersAtIndex(7).contains(.strikethrough))
    }

    func testBlockquoteAtIndex() {
        let textView = createTextViewWithContent()
        let range = NSRange(location: 0, length: 1)

        XCTAssert(!textView.formatIdentifiersAtIndex(1).contains(.blockquote))

        textView.toggleBlockquote(range: range)

        XCTAssert(textView.formatIdentifiersAtIndex(1).contains(.blockquote))

        textView.toggleBlockquote(range: range)

        XCTAssert(!textView.formatIdentifiersAtIndex(1).contains(.blockquote))
    }


    // MARK: - Adding newlines

    /// Tests that entering a newline in an empty editor does not crash it.
    ///
    /// Added to avoid regressions to the bug reported here:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/352
    ///
    func testAddingNewlineOnEmptyEditor() {
        let textView = createTextView(withHTML: "")

        textView.insertText("\n")
    }

    /// Tests that a visual newline is not added at EoF
    ///
    func testNewlineNotAddedAtEof() {
        let textView = createTextView(withHTML: "<p>Testing <b>bold</b> newlines</p>")

        XCTAssertEqual(textView.text, "Testing bold newlines")
    }

    /// Tests that the visual newline is shown at the correct position.
    ///
    /// Added to avoid regressions to the bug reported here:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/387
    ///
    func testNewlineRenderedAtTheCorrectPosition() {
        let textView = createTextView(withHTML: "<p>Testing <b>bold</b> newlines</p>Hey!")

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

        let textView = createTextView(withHTML: "<p>Hello</p><p>World!</p>")

        print(textView.storage.getHTML())

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

        let textView = createTextView(withHTML: "Hello<p>World!</p>")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 5)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(), "HelloWorld!")
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

        let textView = createTextView(withHTML: "<blockquote>Hello</blockquote><p>World!</p>")

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

        let textView = createTextView(withHTML: "<p>Hello</p>World!")

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

        let textView = createTextView(withHTML: "List<ul><li>first</li><li>second</li><li>third</li></ul>")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 4)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(), "Listfirst<ul><li>second</li><li>third</li></ul>")

        let rangeStart2 = textView.position(from: textView.beginningOfDocument, offset: 9)!
        let rangeEnd2 = textView.position(from: rangeStart2, offset: 1)!
        let range2 = textView.textRange(from: rangeStart2, to: rangeEnd2)!

        textView.replace(range2, withText: "")

        XCTAssertEqual(textView.getHTML(), "Listfirstsecond<ul><li>third</li></ul>")

        let rangeStart3 = textView.position(from: textView.beginningOfDocument, offset: 15)!
        let rangeEnd3 = textView.position(from: rangeStart3, offset: 1)!
        let range3 = textView.textRange(from: rangeStart3, to: rangeEnd3)!

        textView.replace(range3, withText: "")

        XCTAssertEqual(textView.getHTML(), "Listfirstsecondthird")
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

        let textView = createTextView(withHTML: "<ol><li>First</li><li>Second</li></ol>Ahoi<br>Arr!")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 12)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(), "<ol><li>First</li><li>SecondAhoi</li></ol>Arr!")
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
        let textView = createTextView(withHTML: html)

        let range = NSRange(location: textView.text.characters.count, length:0)
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
        let textView = createTextView(withHTML: html)

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

        let textView = createTextView(withHTML: "")
        let url = URL(string: linkUrl)!

        textView.setLink(url, title: linkTitle, inRange: insertionRange)

        XCTAssertEqual(textView.getHTML(), "<a href=\"\(linkUrl)\">\(linkTitle)</a>")
    }

    func testToggleBlockquoteWriteOneCharAndDelete() {
        let textView = createEmptyTextView()

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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

        XCTAssertEqual(textView.getHTML(), "<h1>Header</h1>1")
    }

    /// Tests that Newline Characters inserted at the middle of a H1 String won't cause the newline to loose the style.
    ///
    /// Input:
    ///     - "Header Header"
    ///     - "\n" inserted in between the two words
    /// Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/issues/466
    ///
    func testInsertingNewlineAtTheMiddleOfHeaderDoesNotLooseHeaderStyleOnNewline() {
        let textView = createTextView(withHTML: "")

        textView.toggleHeader(.h1, range: .zero)
        textView.insertText("Header Header")

        textView.selectedRange = NSMakeRange("Header".characters.count, 0)
        textView.insertText("\n")

        let identifiers = textView.formatIdentifiersAtIndex(textView.selectedRange.location)
        XCTAssert(identifiers.contains(.header1))

        XCTAssertEqual(textView.getHTML(), "<h1>Header</h1><h1> Header</h1>")
    }


    // MARK: - Unicode tests

    /// Tests that applying bold to a string with unicode characters doesn't crash the app.
    ///
    /// This test was crashing the app as of 2017/04/18.
    ///
    func testBoldWithUnicodeCharacter() {
        let string = "Hello 🌎!"
        let textView = createTextView(withHTML: string)
        let swiftRange = NSRange(location: 0, length: string.characters.count)
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
        let textView = createTextView(withHTML: "")


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
        let textView = createTextView(withHTML: "")

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
        let newline = String(.lineFeed)
        let textView = createTextView(withHTML: "")

        // Toggle List + Move the selection to the EOD
        textView.toggleOrderedList(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        // Insert Newline
        var expectedLength = textView.text.characters.count
        textView.insertText(newline)
        expectedLength += newline.characters.count

        XCTAssertEqual(textView.text.characters.count, expectedLength)
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

        let textView = createTextView(withHTML: "")

        textView.toggleOrderedList(range: .zero)

        textView.insertText(Constants.sampleText0)

        // Select the end of the document
        textView.selectedRange = textView.text.endOfStringNSRange()

        // Delete + Insert Newline
        textView.deleteBackward()
        textView.insertText(newline + Constants.sampleText1)

        // Verify it's still present
        let secondLineIndex = Constants.sampleText0.characters.count + newline.characters.count
        let secondLineRange = NSRange(location: secondLineIndex, length: Constants.sampleText1.characters.count)

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.toggleUnorderedList(range: .zero)
        XCTAssertEqual(textView.text, Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.insertText(Constants.sampleText1)
        textView.insertText(String(.lineFeed))

        XCTAssertEqual(textView.text, Constants.sampleText0 + Constants.sampleText1 + String(.lineFeed) + String(.paragraphSeparator) )
    }

    /// Verifies that toggling an Ordered List, when editing an empty document, inserts a Newline.
    ///
    /// Input:
    ///     - Ordered List
    ///
    /// Ref. Issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/414
    ///
    func testTogglingOrderedListsOnEmptyDocumentsInsertsNewline() {
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.toggleOrderedList(range: .zero)
        XCTAssertEqual(textView.text, Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.insertText(Constants.sampleText1)
        textView.insertText(String(.lineFeed))

        XCTAssertEqual(textView.text, Constants.sampleText0 + Constants.sampleText1 + String(.lineFeed) + String(.paragraphSeparator))
    }

    /// When the caret is positioned at both EoF and EoL, inserting a line separator (in most
    /// editors by pressing shift + enter) must not remove the list style.
    ///
    /// This test is to avoid regressions on:
    /// https://github.com/wordpress-mobile/AztecEditor-iOS/issues/594
    ///
    func testShiftEnterAtEndOfListAndEndOfFile() {
        let textView = createEmptyTextView()

        textView.insertText("First line")
        textView.toggleUnorderedList(range: textView.selectedRange)
        textView.insertText(String(.lineSeparator))

        let unorderedListFormatter = TextListFormatter(style: .unordered)

        XCTAssertTrue(unorderedListFormatter.present(in: textView.storage, at: 0))
        XCTAssertTrue(unorderedListFormatter.present(in: textView.storage, at: textView.selectedRange))
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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        var expectedLength = textView.text.characters.count
        textView.insertText(newline)
        expectedLength += newline.characters.count

        XCTAssertEqual(textView.text.characters.count, expectedLength)
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

        let textView = createTextView(withHTML: "")

        textView.toggleBlockquote(range: .zero)
        textView.insertText(Constants.sampleText0)
        textView.selectedRange = textView.text.endOfStringNSRange()

        // Delete + Insert Newline
        textView.deleteBackward()
        textView.insertText(newline)
        textView.insertText(Constants.sampleText1)

        // Verify it's still present
        let secondLineIndex = Constants.sampleText0.characters.count + newline.characters.count
        let secondLineRange = NSRange(location: secondLineIndex, length: Constants.sampleText1.characters.count)

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.toggleBlockquote(range: .zero)
        XCTAssertEqual(textView.text, Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.insertText(Constants.sampleText1)
        textView.insertText(String(.lineFeed))

        XCTAssertEqual(textView.text, Constants.sampleText0 + Constants.sampleText1 + String(.lineFeed) + String(.paragraphSeparator))
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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

        textView.togglePre(range: .zero)
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)

        var expectedLength = textView.text.characters.count
        textView.insertText(newline)
        expectedLength += newline.characters.count

        XCTAssertEqual(textView.text.characters.count, expectedLength)
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

        let textView = createTextView(withHTML: "")

        textView.togglePre(range: .zero)
        textView.insertText(Constants.sampleText0)
        textView.selectedRange = textView.text.endOfStringNSRange()

        // Delete + Insert Newline
        textView.deleteBackward()
        textView.insertText(newline)
        textView.insertText(Constants.sampleText1)

        // Verify it's still present
        let secondLineIndex = Constants.sampleText0.characters.count + newline.characters.count
        let secondLineRange = NSRange(location: secondLineIndex, length: Constants.sampleText1.characters.count)

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: "")

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
        let textView = createTextView(withHTML: Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.togglePre(range: .zero)
        XCTAssertEqual(textView.text, Constants.sampleText0)

        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        textView.insertText(Constants.sampleText1)
        textView.insertText(String(.lineFeed))
        
        XCTAssertEqual(textView.text, Constants.sampleText0 + Constants.sampleText1 + String(.lineFeed) + String(.paragraphSeparator))
    }

    func testInsertVideo() {
        let textView = createEmptyTextView()
        let _ = textView.replaceWithVideo(at: NSRange(location:0, length:0), sourceURL: URL(string: "video.mp4")!, posterURL: URL(string: "video.jpg"), placeHolderImage: nil)
        XCTAssertEqual(textView.getHTML(), "<video src=\"video.mp4\" poster=\"video.jpg\"></video>")
    }

    func testUpdateVideo() {
        let textView = createTextView(withHTML: "<video src=\"video.mp4\" poster=\"video.jpg\" alt=\"The video\"></video>")
        let videoAttachment = textView.storage.mediaAttachments.first! as! VideoAttachment
        videoAttachment.srcURL = URL(string:"newVideo.mp4")!
        let _ = textView.update(attachment: videoAttachment)

        XCTAssertEqual(textView.getHTML(), "<video src=\"newVideo.mp4\" poster=\"video.jpg\" alt=\"The video\"></video>")
    }

    func testParseVideoWithExtraAttributes() {
        let videoHTML = "<video src=\"newVideo.mp4\" poster=\"video.jpg\" data-wpvideopress=\"videopress\"></video>"
        let textView = createTextView(withHTML: videoHTML)

        XCTAssertEqual(textView.getHTML(), videoHTML)

        guard let attachment = textView.storage.mediaAttachments.first as? VideoAttachment else {
            XCTFail("An video attachment should be present")
            return
        }
        XCTAssertEqual(attachment.namedAttributes["data-wpvideopress"], "videopress", "Property should be available")

        attachment.namedAttributes["data-wpvideopress"] = "ABCDE"

        XCTAssertEqual(textView.getHTML(), "<video src=\"newVideo.mp4\" poster=\"video.jpg\" data-wpvideopress=\"ABCDE\"></video>")
    }

    /// This test check if the insertion of a Comment Attachment works correctly and the expected tag gets inserted
    ///
    func testInsertComment() {
        let textView = createEmptyTextView()

        textView.replaceWithComment(at: .zero, text: "more")
        let html = textView.getHTML()

        XCTAssertEqual(html, "<!--more-->")
    }

    /// This test check if the insertion of a Comment Attachment works correctly and the expected tag gets inserted
    ///
    func testInsertCommentAttachmentDoNotCrashTheEditorWhenCalledSequentially() {
        let textView = createEmptyTextView()
        textView.replaceWithComment(at: .zero, text: "more")
        textView.replaceWithComment(at: .zero, text: "some other comment should go here")

        let html = textView.getHTML()

        XCTAssertEqual(html, "<!--some other comment should go here--><!--more-->")
    }

    /// This test check if the insertion of an horizontal ruler works correctly and the hr tag is inserted
    ///
    func testReplaceRangeWithHorizontalRuler() {
        let textView = createEmptyTextView()

        textView.replaceWithHorizontalRuler(at: .zero)
        let html = textView.getHTML()

        XCTAssertEqual(html, "<hr>")
    }

    /// This test check if the insertion of antwo horizontal ruler works correctly and the hr tag(s) are inserted
    ///
    func testReplaceRangeWithHorizontalRulerGeneratesExpectedHTMLWhenExecutedSequentially() {
        let textView = createEmptyTextView()

        textView.replaceWithHorizontalRuler(at: .zero)
        textView.replaceWithHorizontalRuler(at: .zero)
        let html = textView.getHTML()

        XCTAssertEqual(html, "<hr><hr>")
    }

    /// This test check if the insertion of an horizontal ruler over an image attachment works correctly and the hr tag is inserted
    ///
    func testReplaceRangeWithHorizontalRulerRulerOverImage() {
        let textView = createEmptyTextView()

        textView.replaceWithImage(at: .zero, sourceURL: URL(string:"https://wordpress.com")!, placeHolderImage: nil)
        textView.replaceWithHorizontalRuler(at: NSRange(location: 0, length:1))

        let html = textView.getHTML()
        
        XCTAssertEqual(html, "<hr>")
    }

    func testReplaceRangeWithAttachmentDontDisableDefaultParagraph() {
        let textView = createEmptyTextView()

        textView.replaceWithImage(at: .zero, sourceURL: URL(string:"https://wordpress.com")!, placeHolderImage: nil)

        let html = textView.getHTML()

        XCTAssertEqual(html, "<img src=\"https://wordpress.com\">")

        textView.selectedRange = NSRange(location: NSAttributedString.lengthOfTextAttachment, length: 1)
        guard let font = textView.typingAttributes[NSFontAttributeName] as? UIFont else {
            XCTFail("Font should be set")
            return
        }
        XCTAssertEqual(font, textView.defaultFont)
    }

    func testInsertEmojiKeepsDefaultFont() {
        let textView = createEmptyTextViewWithNonStandardSystemFont()

        textView.insertText("😘")
        let currentTypingFont = textView.typingAttributes[NSFontAttributeName] as! UIFont
        XCTAssertEqual(currentTypingFont, nonStandardSystemFont, "Font should be set to default")
    }



    func testRemovalOfAttachment() {
        let textView = createEmptyTextView()

        let attachment = textView.replaceWithImage(at: .zero, sourceURL: URL(string:"https://wordpress.com")!, placeHolderImage: nil)

        var html = textView.getHTML()

        XCTAssertEqual(html, "<img src=\"https://wordpress.com\">")

        textView.remove(attachmentID: attachment.identifier)

        html = textView.getHTML()

        XCTAssertEqual(html, "")
    }

    /// This test verifies that the H1 Header does not get lost during the Rich <> Raw transitioning.
    ///
    func testToggleHtmlWithTwoEmptyLineBreaksDoesNotLooseHeaderStyle() {
        let pristineHTML = "<br><br><h1>Header</h1>"
        let textView = createTextView(withHTML: pristineHTML)
        let generatedHTML = textView.getHTML()

        XCTAssertEqual(pristineHTML, generatedHTML)
    }

    /// This test verifies that the H1 Header does not get lost, in the scenario in which the H1 is contained
    /// within the second line of text (and thus, would be expected to get rendered below!).
    ///
    func testToggleHtmlWithTwoLineBreaksAndInlineHeaderDoesNotLooseHeaderStyle() {
        let pristineHTML = "<br>1<br>2<h1>Heder</h1>"
        let textView = createTextView(withHTML: pristineHTML)
        let generatedHTML = textView.getHTML()

        XCTAssertEqual(pristineHTML, generatedHTML)
    }
}
