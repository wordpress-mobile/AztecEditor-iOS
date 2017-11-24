    import XCTest

public struct elementStringIDs {
    // Demo Menu
    static var emptyDemo = "Empty Editor Demo"
    static var demo = "Editor Demo"

    // Text Fields
    static var titleTextField = "Title"
    static var richTextField = "richContentView"
    static var htmlTextField = "HTMLContentView"

    // Alerts
    static var insertLinkConfirmButton = "Insert Link"
    
    // Table cells
    static var unorderedListOption = "Unordered List"
    static var orderedListOption = "Ordered List"

    // Toolbar
    static var mediaButton = "formatToolbarInsertMedia"
    static var headerButton = "formatToolbarSelectParagraphStyle"
    static var boldButton = "formatToolbarToggleBold"
    static var italicButton = "formatToolbarToggleItalic"
    static var underlineButton = "formatToolbarToggleUnderline"
    static var strikethroughButton = "formatToolbarToggleStrikethrough"
    static var blockquoteButton = "formatToolbarToggleBlockquote"
    static var orderedlistButton = "formatToolbarToggleListOrdered"
    static var unorderedlistButton = "formatToolbarToggleListUnordered"
    static var linkButton = "formatToolbarInsertLink"
    static var horizontalrulerButton = "formatToolbarInsertHorizontalRuler"
    static var sourcecodeButton = "formatToolbarToggleHtmlView"
    static var moreButton = "formatToolbarInsertMore"
    static var header1Button = "Heading 1"
    static var header2Button = "Heading 2"
    static var header3Button = "Heading 3"
    static var header4Button = "Heading 4"
    static var header5Button = "Heading 5"
    static var header6Button = "Heading 6"
    
    // Menu items
    static var copyButton = "Copy"
    static var pasteButton = "Paste"
    
}

extension XCTest {
    /**
     Common method to type in different text fields
     */
    func typeToTextField(text: String, to: String) -> Void {
        let app = XCUIApplication()
        let textField = app.textViews[to]
        
        textField.typeText(text)
    }
    
    /**
     Enters text in the rich text field with auto-correction disabled
     - Parameter text: the test to enter into the field
     */
    func enterTextInField(text: String) -> Void {
        typeToTextField(text: text, to: elementStringIDs.richTextField)
//        let app = XCUIApplication()
//        let richTextField = app.textViews[elementStringIDs.richTextField]
//
//        richTextField.typeText(text)
    }
    
    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    func enterTextInTitle(text: String) -> Void {
        typeToTextField(text: text, to: elementStringIDs.titleTextField)
    }
    
    /**
     Enters text into HTML field.
     - Parameter text: the test to enter into the title
     */
    func enterTextInHTML(text: String) -> Void {
        typeToTextField(text: text, to: elementStringIDs.htmlTextField)
    }

    /**
     Selects all entered text in the rich text field
     */
    func selectAllTextInField() -> Void {
        let app = XCUIApplication()
        let richTextField = app.textViews[elementStringIDs.richTextField]
        
        richTextField.press(forDuration: 1.2)
        app.menuItems.element(boundBy: 1).tap()
    }
    
    /**
     Selects all entered text in the rich text field
     */
    func selectAllTextInHTMLField() -> Void {
        selectAllText(field: elementStringIDs.htmlTextField)
    }

    
    /**
     Selects all entered text in provided textView element
     */
    func selectAllText(field: String) -> Void {
        let app = XCUIApplication()
        let richTextField = app.textViews[field]
        
        richTextField.press(forDuration: 1.2)
        app.menuItems.element(boundBy: 1).tap()
    }

    /**
     Gets the contents of the HTML text view
     */
    func getHTMLContent() -> String {
        let app = XCUIApplication()
        
        // Expects the format bar to be expanded.
        let elementsQuery = app.scrollViews.otherElements
        let htmlButton = elementsQuery.buttons[elementStringIDs.sourcecodeButton]
        if (!htmlButton.isHittable) {
            elementsQuery.buttons[elementStringIDs.mediaButton].swipeLeft()
        }
        htmlButton.tap()
        
        let htmlContentTextView =
            app.textViews[elementStringIDs.htmlTextField]
        let text = htmlContentTextView.value as! String
        
        // Remove spaces between HTML tags.
        let regex = try! NSRegularExpression(pattern: ">\\s+?<", options: .caseInsensitive)
        let range = NSMakeRange(0, text.count)
        let strippedText = regex.stringByReplacingMatches(in: text, options: .reportCompletion, range: range, withTemplate: "><")

        return strippedText
    }
    
    func getRichTextContent() -> String {
        let app = XCUIApplication()
        
        let richContentTextView = app.textViews[elementStringIDs.richTextField]
        let text = richContentTextView.value as! String
        return text
    }
    
    /**
     Switch Content view between Rich text & HTML
     */
    func switchContentView() -> Void {
        let app = XCUIApplication()

        // TODO: Switch content is not possible when bar is locked. Need to determinate the status of options bar. ATM its impossible.
//        let button = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
//        XCTAssert(!button.isHittable, "Options bar is locked. SourceCode button is not available")
    
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.buttons[elementStringIDs.mediaButton].swipeLeft()
        elementsQuery.buttons[elementStringIDs.sourcecodeButton].tap()
    }
    
    func gotoRootPage() -> Void {
        let app = XCUIApplication()

        return app.navigationBars["AztecExample.EditorDemo"].buttons["Root View Controller"].tap()
    }
}
