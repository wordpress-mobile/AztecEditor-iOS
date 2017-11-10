import XCTest

public struct elementStringIDs {
    // Demo Menu
    static var emptyDemo = "Empty Editor Demo"

    // Text Fields
    static var titleTextField = "Title"
    static var richTextField = "richContentView"
    static var htmlTextField = "HTMLContentView"

    // Alerts
    static var insertLinkConfirmButton = "Insert Link"

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
     Gets the contents of the HTML text view
     */
    func getHTMLContent() -> String {
        let app = XCUIApplication()

        app.buttons[elementStringIDs.sourcecodeButton].tap()
        let htmlContentTextView = app.textViews[elementStringIDs.htmlTextField]
        let text = htmlContentTextView.value as! String
        return text
    }
    
    /**
     Switch Content view between Rich text & HTML
     */
    func switchContentView() -> Void {
        let app = XCUIApplication()
        
        app.buttons[elementStringIDs.sourcecodeButton].tap()
        let el = app.textViews[elementStringIDs.htmlTextField]
//        if el.exists && el.isHittable {
//            return app.textViews[elementStringIDs.htmlTextField].tap()
//        }
//        return app.textViews[elementStringIDs.richTextField].tap()
    }
    
    func gotoRootPage() -> Void {
        let app = XCUIApplication()

        return app.navigationBars["AztecExample.EditorDemo"].buttons["Root View Controller"].tap()
    }
}
