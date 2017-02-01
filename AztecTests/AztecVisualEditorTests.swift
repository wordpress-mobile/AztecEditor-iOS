import XCTest
@testable import Aztec
import Gridicons

class AztecVisualEditorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        let range = NSRange(location: 3, length: 3)
        let identifiers = editor.formatIdentifiersSpanningRange(range)

        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)
    }

    func testFormatIdentifiersAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        var identifiers = editor.formatIdentifiersAtIndex(4)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)

        identifiers = editor.formatIdentifiersAtIndex(5)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)

        identifiers = editor.formatIdentifiersAtIndex(6)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)


        identifiers = editor.formatIdentifiersAtIndex(0)
        XCTAssert(identifiers.count == 0)

        identifiers = editor.formatIdentifiersAtIndex(3)
        XCTAssert(identifiers.count == 0)

        identifiers = editor.formatIdentifiersAtIndex(7)
        XCTAssert(identifiers.count == 0)
    }

    // MARK: - Toggle Attributes

    func testToggleBold() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.bold))

        editor.toggleBold(range: range)

        XCTAssert(!editor.formatIdentifiersSpanningRange(range).contains(.bold))

        editor.toggleBold(range: range)

        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.bold))
    }

    func testToggleItalic() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.italic))

        editor.toggleItalic(range: range)

        XCTAssert(!editor.formatIdentifiersSpanningRange(range).contains(.italic))

        editor.toggleItalic(range: range)

        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.italic))
    }

    func testToggleUnderline() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.underline))

        editor.toggleUnderline(range: range)

        XCTAssert(!editor.formatIdentifiersSpanningRange(range).contains(.underline))

        editor.toggleUnderline(range: range)

        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.underline))
    }

    func testToggleStrike() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.strikethrough))

        editor.toggleStrikethrough(range: range)

        XCTAssert(!editor.formatIdentifiersSpanningRange(range).contains(.strikethrough))

        editor.toggleStrikethrough(range: range)

        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.strikethrough))
    }

    func testToggleBlockquote() {
        let editor = editorConfiguredWithParagraphs()
        let length = paragraph.characters.count
        let range = NSRange(location: 0, length: length)

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.formatIdentifiersAtIndex(1).contains(.blockquote))
        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.blockquote))

        editor.toggleBlockquote(range: range)

        XCTAssert(!editor.formatIdentifiersAtIndex(1).contains(.blockquote))
        XCTAssert(!editor.formatIdentifiersSpanningRange(range).contains(.blockquote))
    }

    func testToggleOrderedList() {
        let editor = editorConfiguredWithParagraphs()
        let length = paragraph.characters.count
        let range = NSRange(location: 0, length: length)

        editor.toggleOrderedList(range: range)

        XCTAssert(editor.formatIdentifiersAtIndex(0).contains(.orderedlist))
        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.orderedlist))

        editor.toggleOrderedList(range: range)

        XCTAssert(!editor.formatIdentifiersAtIndex(0).contains(.orderedlist))
        XCTAssert(!editor.formatIdentifiersSpanningRange(range).contains(.orderedlist))
    }

    func testToggleUnorderedList() {
        let editor = editorConfiguredWithParagraphs()
        let length = paragraph.characters.count
        let range = NSRange(location: 0, length: length)

        editor.toggleUnorderedList(range: range)

        XCTAssert(editor.formatIdentifiersAtIndex(0).contains(.unorderedlist))
        XCTAssert(editor.formatIdentifiersSpanningRange(range).contains(.unorderedlist))

        editor.toggleOrderedList(range: range)

        XCTAssert(!editor.formatIdentifiersAtIndex(0).contains(.unorderedlist))
        XCTAssert(!editor.formatIdentifiersSpanningRange(range).contains(.unorderedlist))
    }

    // MARK: - Test Attributes Exist

    func check(editor: TextView, range:NSRange, forIndentifier identifier: FormattingIdentifier) -> Bool {
        return editor.formatIdentifiersSpanningRange(range).contains(identifier)
    }

    func testBoldSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.bold))
        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.bold))
        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.bold))

        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.bold))
        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.bold))
    }

    func testItalicSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")

        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.italic))
        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.italic))
        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.italic))

        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.italic))
        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.italic))
    }

    func testUnderlineSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")

        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.underline))
        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.underline))
        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.underline))

        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.underline))
        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.underline))
    }

    func testStrikethroughSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 3)).contains(.strikethrough))
        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 2)).contains(.strikethrough))
        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 3, length: 1)).contains(.strikethrough))

        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 2, length: 3)).contains(.strikethrough))
        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 4, length: 3)).contains(.strikethrough))
    }

    func testBlockquoteSpansRange() {
        let editor = editorConfiguredWithParagraphs()
        let range = NSRange(location: 0, length: 1)
        let length = "Lorem ipsum dolar sit amet.\n".characters.count

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.formatIdentifiersSpanningRange(NSRange(location: 0, length: length)).contains(.blockquote))
        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 0, length: length + 1)).contains(.blockquote))
        XCTAssert(!editor.formatIdentifiersSpanningRange(NSRange(location: 1, length: length)).contains(.blockquote))
    }

    func testBoldAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        XCTAssert(editor.formatIdentifiersAtIndex(4).contains(.bold))
        XCTAssert(editor.formatIdentifiersAtIndex(5).contains(.bold))
        XCTAssert(editor.formatIdentifiersAtIndex(6).contains(.bold))

        XCTAssert(!editor.formatIdentifiersAtIndex(2).contains(.bold))
        XCTAssert(!editor.formatIdentifiersAtIndex(7).contains(.bold))
    }

    func testItalicAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")

        XCTAssert(editor.formatIdentifiersAtIndex(4).contains(.italic))
        XCTAssert(editor.formatIdentifiersAtIndex(5).contains(.italic))
        XCTAssert(editor.formatIdentifiersAtIndex(6).contains(.italic))

        XCTAssert(!editor.formatIdentifiersAtIndex(2).contains(.italic))
        XCTAssert(!editor.formatIdentifiersAtIndex(7).contains(.italic))
    }

    func testUnderlineAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")

        XCTAssert(editor.formatIdentifiersAtIndex(4).contains(.underline))
        XCTAssert(editor.formatIdentifiersAtIndex(5).contains(.underline))
        XCTAssert(editor.formatIdentifiersAtIndex(6).contains(.underline))

        XCTAssert(!editor.formatIdentifiersAtIndex(2).contains(.underline))
        XCTAssert(!editor.formatIdentifiersAtIndex(7).contains(.underline))
    }

    func testStrikethroughAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(editor.formatIdentifiersAtIndex(4).contains(.strikethrough))
        XCTAssert(editor.formatIdentifiersAtIndex(5).contains(.strikethrough))
        XCTAssert(editor.formatIdentifiersAtIndex(6).contains(.strikethrough))

        XCTAssert(!editor.formatIdentifiersAtIndex(2).contains(.strikethrough))
        XCTAssert(!editor.formatIdentifiersAtIndex(7).contains(.strikethrough))
    }

    func testBlockquoteAtIndex() {
        let editor = editorConfiguredWithParagraphs()
        let range = NSRange(location: 0, length: 1)

        XCTAssert(!editor.formatIdentifiersAtIndex(1).contains(.blockquote))

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.formatIdentifiersAtIndex(1).contains(.blockquote))

        editor.toggleBlockquote(range: range)

        XCTAssert(!editor.formatIdentifiersAtIndex(1).contains(.blockquote))
    }

    // MARK: - Helpers
    let paragraph = "Lorem ipsum dolar sit amet.\n"

    func editorConfiguredForTesting(withHTML html: String) -> Aztec.TextView {
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        richTextView.setHTML(html)

        return richTextView
    }

    func editorConfiguredWithParagraphs() -> Aztec.TextView {
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
}
