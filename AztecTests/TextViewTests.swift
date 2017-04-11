import XCTest
@testable import Aztec
import Gridicons

class AztecVisualTextViewTests: XCTestCase {
    
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
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        return richTextView
    }

    func createTextView(withHTML html: String) -> Aztec.TextView {
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        richTextView.setHTML(html)

        return richTextView
    }

    func createTextViewWithContent() -> Aztec.TextView {
        let paragraph = "Lorem ipsum dolar sit amet.\n"
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

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

        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

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
        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        textView.text = "foo"

        let count = textView.text!.characters.count
        let maxIndex = count - 1

        // Test upper and lower bounds
        XCTAssert(maxIndex == textView.maxIndex(100))
        XCTAssert(0 == textView.maxIndex(0))
    }

    func testAdjustedIndex() {
        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

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

    /// Tests that the visual newline is shown at the correct position.
    ///
    /// Added to avoid regressions to the bug reported here:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/387
    ///
    func testNewlineRenderedAtTheCorrectPosition() {
        let textView = createTextView(withHTML: "<p>Testing <b>bold</b> newlines</p>")

        XCTAssertEqual(textView.text, "Testing bold newlines\n")
    }

    // MARK: - Deleting newlines
/*
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
    ///     - Initial HTML: "<ol><li>First</li><li>Second</li></ol>Ahoi<br>Arr!"
    ///     - Deletion range: (loc: 12, len 1)
    ///
    /// Output:
    ///     - Final HTML: "<ol><li>First</li><li>SecondAhoi</li></ol>Arr!"
    ///
    func testDeleteNewline6() {

        let textView = createTextView(withHTML: "<ol><li>First</li><li>Second</li></ol>Ahoi<br>Arr!")

        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: 12)!
        let rangeEnd = textView.position(from: rangeStart, offset: 1)!
        let range = textView.textRange(from: rangeStart, to: rangeEnd)!

        textView.replace(range, withText: "")

        XCTAssertEqual(textView.getHTML(), "<ol><li>First</li><li>SecondAhoi</li></ol>Arr!")
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
    func testDeleteNewline7() {

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
    ///     - Initial HTML: "<h1>Header</h1>\n"
    ///     - Deletion range: (loc: 5, len 1)
    ///
    /// Output:
    ///     - Final HTML: "<h1>Header</h1>"
    ///
    func testDeleteNewlineAtEndOfText() {
        let html = "<h1>Header</h1>\n"
        let textView = createTextView(withHTML: html)

        let range = NSRange(location:html.characters.count, length:0)
        textView.selectedRange = range
        textView.deleteBackward()

        XCTAssertEqual(textView.getHTML(), "<h1>Header</h1>")
    }*/

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
}
