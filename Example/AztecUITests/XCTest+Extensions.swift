    import XCTest

public struct elementStringIDs {
    // Demo Menu
    static let emptyDemo = "Empty Editor Demo"
    static let demo = "Editor Demo"

    // Text Fields
    static let titleTextField = "Title"
    static let richTextField = "richContentView"
    static let htmlTextField = "HTMLContentView"

    // Alerts
    static let insertLinkConfirmButton = "insertLinkButton"
    
    // Table cells
    static let unorderedListOption = "Unordered List"
    static let orderedListOption = "Ordered List"

    // Toolbar
    static let mediaButton = "formatToolbarInsertMedia"
    static let headerButton = "formatToolbarSelectParagraphStyle"
    static let boldButton = "formatToolbarToggleBold"
    static let italicButton = "formatToolbarToggleItalic"
    static let underlineButton = "formatToolbarToggleUnderline"
    static let strikethroughButton = "formatToolbarToggleStrikethrough"
    static let blockquoteButton = "formatToolbarToggleBlockquote"
    static let orderedlistButton = "formatToolbarToggleListOrdered"
    static let unorderedlistButton = "formatToolbarToggleListUnordered"
    static let linkButton = "formatToolbarInsertLink"
    static let horizontalrulerButton = "formatToolbarInsertHorizontalRuler"
    static let sourcecodeButton = "formatToolbarToggleHtmlView"
    static let moreButton = "formatToolbarInsertMore"
    static let header1Button = "Heading 1"
    static let header2Button = "Heading 2"
    static let header3Button = "Heading 3"
    static let header4Button = "Heading 4"
    static let header5Button = "Heading 5"
    static let header6Button = "Heading 6"
    
    // Menu items
    static let copyButton = "Copy"
    static let pasteButton = "Paste"
    static let selectButton = "Select"
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
        
        // Expects the format bar to be expanded.
        let elementsQuery = app.scrollViews.otherElements
        let htmlButton = elementsQuery.buttons[elementStringIDs.sourcecodeButton]
        if (!htmlButton.isHittable) {
            elementsQuery.buttons[elementStringIDs.linkButton].swipeLeft()
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
    
    func isIPhone() -> Bool {
        let app = XCUIApplication()
        return app.windows.element(boundBy: 0).horizontalSizeClass == .compact || app.windows.element(boundBy: 0).verticalSizeClass == .compact
    }
}
    
    extension XCUIElement {
        /**
         Removes any current text in the field before typing in the new value
         - Parameter text: the text to enter into the field
         */
        func replaceText(text: String) {
            guard let stringValue = self.value as? String else {
                XCTFail("Tried to clear and enter text into a non string value")
                return
            }
            
            self.tap()
            
//            let deleteString = stringValue.characters.map { _ in "\u{8}" }.joined(separator: "")
            let deleteString = stringValue.map { _ in "\u{8}" }.joined(separator: "")
            
            self.typeText(deleteString)
            self.typeText(text)
        }
    }
