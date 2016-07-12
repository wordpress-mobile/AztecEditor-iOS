import XCTest
import Aztec

class AztecTextEditorTests: XCTestCase {
    
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

        let textView = AztecTextEditor.createTextView()

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

}
