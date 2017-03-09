import XCTest
@testable import Aztec
import Gridicons

class AztecVisualtextViewTests: XCTestCase {
    
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

    /// This test was created to prevent regressions related to this issue:
    /// https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/350
    ///
    func testToggleBlockquoteAndStrikethrough() {
        let textView = createEmptyTextView()

        textView.toggleStrikethrough(range: NSRange.zero)
        textView.toggleBlockquote(range: NSRange.zero)

        // There's no need to check any condition, as long as the test doesn't crash.
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
}
