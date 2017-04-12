import XCTest

public struct elementStringIDs {
    // Demo Menu
    static var emptyDemo = "Empty Editor Demo"

    // Text Fields
    static var richTextField = "richContentView"
    static var htmlTextField = "HTMLContentView"

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

extension XCUIElement {
    /**
     Enters text in the field and then selects all entered text
     - Parameter text: the text to enter into the field
    */
    func enterAndSelectText(text: String) -> Void {
        let app = XCUIApplication()

        self.typeText(text)
        self.press(forDuration: 1.2)
        app.menuItems.element(boundBy: 1).tap()
    }
}
