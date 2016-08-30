import XCTest
@testable import Aztec

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

        let textView = AztecVisualEditor.createTextView()

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
        XCTAssert(textView.textStorage.isKindOfClass(AztecTextStorage))
    }


    // MARK: - Test Index Wrangling

    func testMaxIndex() {
        let textView = AztecVisualEditor.createTextView()
        let editor = AztecVisualEditor(textView: textView)

        textView.text = "foo"

        let count = textView.text!.characters.count
        let maxIndex = count - 1

        // Test upper and lower bounds
        XCTAssert(maxIndex == editor.maxIndex(100))
        XCTAssert(0 == editor.maxIndex(0))
    }

    func testAdjustedIndex() {
        let textView = AztecVisualEditor.createTextView()
        let editor = AztecVisualEditor(textView: textView)

        textView.text = "foobarbaz"

        let count = textView.text!.characters.count
        let maxIndex = count - 1

        // Test upper and lower bounds.
        // Remember that an adjusted character index should be one less than 
        // the NSRange.location.
        XCTAssert(maxIndex - 1 == editor.adjustedIndex(100))
        XCTAssert(0 == editor.adjustedIndex(0))
        XCTAssert(0 == editor.adjustedIndex(1))
        XCTAssert(1 == editor.adjustedIndex(2))
    }


    // MARK: - Retrieve Format Identifiers

    func testFormatIdentifiersSpanningRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        let range = NSRange(location: 3, length: 3)
        let identifiers = editor.formatIdentifiersSpanningRange(range)

        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == "bold")
    }

    func testFormatIdentifiersAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        var identifiers = editor.formatIdentifiersAtIndex(4)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == "bold")

        identifiers = editor.formatIdentifiersAtIndex(5)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == "bold")

        identifiers = editor.formatIdentifiersAtIndex(6)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == "bold")


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

        XCTAssert(editor.boldFormattingSpansRange(range))

        editor.toggleBold(range: range)

        XCTAssert(!editor.boldFormattingSpansRange(range))

        editor.toggleBold(range: range)

        XCTAssert(editor.boldFormattingSpansRange(range))
    }

    func testToggleItalic() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.italicFormattingSpansRange(range))

        editor.toggleItalic(range: range)

        XCTAssert(!editor.italicFormattingSpansRange(range))

        editor.toggleItalic(range: range)

        XCTAssert(editor.italicFormattingSpansRange(range))
    }

    func testToggleUnderline() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.underlineFormattingSpansRange(range))

        editor.toggleUnderline(range: range)

        XCTAssert(!editor.underlineFormattingSpansRange(range))

        editor.toggleUnderline(range: range)

        XCTAssert(editor.underlineFormattingSpansRange(range))
    }

    func testToggleStrike() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.strikethroughFormattingSpansRange(range))

        editor.toggleStrikethrough(range: range)

        XCTAssert(!editor.strikethroughFormattingSpansRange(range))

        editor.toggleStrikethrough(range: range)

        XCTAssert(editor.strikethroughFormattingSpansRange(range))
    }

    func testToggleBlockquote() {
        let editor = editorConfiguredWithParagraphs()
        let range = NSRange(location: 0, length: 1)
        let length = "Lorem ipsum dolar sit amet.\n".length

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.formattingAtIndexContainsBlockquote(1))
        XCTAssert(editor.blockquoteFormattingSpansRange(NSRange(location: 0, length: length)))

        editor.toggleBlockquote(range: range)

        XCTAssert(!editor.formattingAtIndexContainsBlockquote(1))
        XCTAssert(!editor.blockquoteFormattingSpansRange(NSRange(location: 0, length: length)))
    }

    func testToggleOrderedList() {
        // TODO
    }

    func testToggleUnorderedList() {
        // TODO
    }

    func testInsertLink() {
        // TODO
    }

    // MARK: - Test Attributes Exist

    func testBoldSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        XCTAssert(editor.boldFormattingSpansRange(NSRange(location: 3, length: 3)))
        XCTAssert(editor.boldFormattingSpansRange(NSRange(location: 3, length: 2)))
        XCTAssert(editor.boldFormattingSpansRange(NSRange(location: 3, length: 1)))

        XCTAssert(!editor.boldFormattingSpansRange(NSRange(location: 2, length: 3)))
        XCTAssert(!editor.boldFormattingSpansRange(NSRange(location: 4, length: 3)))
    }

    func testItalicSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")

        XCTAssert(editor.italicFormattingSpansRange(NSRange(location: 3, length: 3)))
        XCTAssert(editor.italicFormattingSpansRange(NSRange(location: 3, length: 2)))
        XCTAssert(editor.italicFormattingSpansRange(NSRange(location: 3, length: 1)))

        XCTAssert(!editor.italicFormattingSpansRange(NSRange(location: 2, length: 3)))
        XCTAssert(!editor.italicFormattingSpansRange(NSRange(location: 4, length: 3)))
    }

    func testUnderlineSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")

        XCTAssert(editor.underlineFormattingSpansRange(NSRange(location: 3, length: 3)))
        XCTAssert(editor.underlineFormattingSpansRange(NSRange(location: 3, length: 2)))
        XCTAssert(editor.underlineFormattingSpansRange(NSRange(location: 3, length: 1)))

        XCTAssert(!editor.underlineFormattingSpansRange(NSRange(location: 2, length: 3)))
        XCTAssert(!editor.underlineFormattingSpansRange(NSRange(location: 4, length: 3)))
    }

    func testStrikethroughSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(editor.strikethroughFormattingSpansRange(NSRange(location: 3, length: 3)))
        XCTAssert(editor.strikethroughFormattingSpansRange(NSRange(location: 3, length: 2)))
        XCTAssert(editor.strikethroughFormattingSpansRange(NSRange(location: 3, length: 1)))

        XCTAssert(!editor.strikethroughFormattingSpansRange(NSRange(location: 2, length: 3)))
        XCTAssert(!editor.strikethroughFormattingSpansRange(NSRange(location: 4, length: 3)))
    }

    func testBlockquoteSpansRange() {
        let editor = editorConfiguredWithParagraphs()
        let range = NSRange(location: 0, length: 1)
        let length = "Lorem ipsum dolar sit amet.\n".length

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.blockquoteFormattingSpansRange(NSRange(location: 0, length: length)))
        XCTAssert(!editor.blockquoteFormattingSpansRange(NSRange(location: 0, length: length + 1)))
        XCTAssert(!editor.blockquoteFormattingSpansRange(NSRange(location: 1, length: length)))
    }

    func testBoldAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        XCTAssert(editor.formattingAtIndexContainsBold(3))
        XCTAssert(editor.formattingAtIndexContainsBold(4))
        XCTAssert(editor.formattingAtIndexContainsBold(5))

        XCTAssert(!editor.formattingAtIndexContainsBold(2))
        XCTAssert(!editor.formattingAtIndexContainsBold(6))
    }

    func testItalicAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")

        XCTAssert(editor.formattingAtIndexContainsItalic(3))
        XCTAssert(editor.formattingAtIndexContainsItalic(4))
        XCTAssert(editor.formattingAtIndexContainsItalic(5))

        XCTAssert(!editor.formattingAtIndexContainsItalic(2))
        XCTAssert(!editor.formattingAtIndexContainsItalic(6))
    }

    func testUnderlineAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")

        XCTAssert(editor.formattingAtIndexContainsUnderline(3))
        XCTAssert(editor.formattingAtIndexContainsUnderline(4))
        XCTAssert(editor.formattingAtIndexContainsUnderline(5))

        XCTAssert(!editor.formattingAtIndexContainsUnderline(2))
        XCTAssert(!editor.formattingAtIndexContainsUnderline(6))
    }

    func testStrikethroughAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(editor.formattingAtIndexContainsStrikethrough(3))
        XCTAssert(editor.formattingAtIndexContainsStrikethrough(4))
        XCTAssert(editor.formattingAtIndexContainsStrikethrough(5))

        XCTAssert(!editor.formattingAtIndexContainsStrikethrough(2))
        XCTAssert(!editor.formattingAtIndexContainsStrikethrough(6))
    }

    func testBlockquoteAtIndex() {
        let editor = editorConfiguredWithParagraphs()
        let range = NSRange(location: 0, length: 1)

        XCTAssert(!editor.formattingAtIndexContainsBlockquote(1))

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.formattingAtIndexContainsBlockquote(1))

        editor.toggleBlockquote(range: range)

        XCTAssert(!editor.formattingAtIndexContainsBlockquote(1))
    }

    // MARK: - Helpers

    func editorConfiguredForTesting(withHTML html: String) -> AztecVisualEditor {
        let textView = AztecVisualEditor.createTextView()
        let editor = AztecVisualEditor(textView: textView)

        editor.setHTML(html)

        return editor
    }

    func editorConfiguredWithParagraphs() -> AztecVisualEditor {
        let textView = AztecVisualEditor.createTextView()
        let editor = AztecVisualEditor(textView: textView)

        let attributes = [NSParagraphStyleAttributeName : NSParagraphStyle()]
        let paragraph = "Lorem ipsum dolar sit amet.\n"
        let templateString = NSMutableAttributedString(string: paragraph, attributes: attributes)

        let attrStr = NSMutableAttributedString()
        attrStr.appendAttributedString(templateString)
        attrStr.appendAttributedString(templateString)
        attrStr.appendAttributedString(templateString)
        textView.attributedText = attrStr

        return editor
    }
}
