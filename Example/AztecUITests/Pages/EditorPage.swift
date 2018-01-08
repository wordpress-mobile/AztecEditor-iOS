import Foundation
import XCTest

class EditorPage: BasePage {

    enum Mode {
        case rich
        case html

        func toggle() -> Mode {
            return self == .rich ? .html : .rich
        }
    }

    var textField: String!
    var mode: Mode
    var textView: XCUIElement

    private var titleTextField = "Title"
    private var richTextField = "richContentView"
    private var htmlTextField = "HTMLContentView"
    
    lazy var mediaButton = XCUIApplication().buttons["formatToolbarInsertMedia"]
    lazy var headerButton = XCUIApplication().buttons["formatToolbarSelectParagraphStyle"]
    lazy var boldButton = XCUIApplication().buttons["formatToolbarToggleBold"]
    lazy var italicButton = XCUIApplication().buttons["formatToolbarToggleItalic"]
    lazy var underlineButton = XCUIApplication().buttons["formatToolbarToggleUnderline"]
    lazy var strikethroughButton = XCUIApplication().buttons["formatToolbarToggleStrikethrough"]
    lazy var blockquoteButton = XCUIApplication().buttons["formatToolbarToggleBlockquote"]
    lazy var unorderedlistButton = XCUIApplication().buttons["formatToolbarToggleListUnordered"]
    lazy var linkButton = XCUIApplication().buttons["formatToolbarInsertLink"]
    lazy var horizontalrulerButton = XCUIApplication().buttons["formatToolbarInsertHorizontalRuler"]
    lazy var sourcecodeButton = XCUIApplication().buttons["formatToolbarToggleHtmlView"]
    lazy var moreButton = XCUIApplication().buttons["formatToolbarInsertMore"]

    init(mode: Mode) {
        textField = ""
        self.mode = mode
        switch mode {
        case .rich:
            textField = richTextField
        case .html:
            textField = htmlTextField
        }

        let app = XCUIApplication()
        textView = app.textViews[textField]
        
        if !textView.exists {
            if app.otherElements[textField].exists {
                textView = app.otherElements[textField]
            }
        }
        
        super.init(element: textView)
      
        showOptionsStrip()
    }
    
    func showOptionsStrip() -> Void {
        textView.coordinate(withNormalizedOffset: .zero).tap()
        expandOptionsSctrip()
    }
    
    func expandOptionsSctrip() -> Void {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        let htmlButton = app.scrollViews.otherElements.buttons[elementStringIDs.sourcecodeButton]
        
        if expandButton.exists && expandButton.isHittable && !htmlButton.exists {
            expandButton.tap()
        }
    }

    @discardableResult
    func addList(type: String) -> EditorPage {
        toolbarButtonTap(locator: elementStringIDs.unorderedlistButton)
        var listType = ""
        if type == "ul" {
            listType = elementStringIDs.unorderedListOption
        } else if type == "ol" {
            listType = elementStringIDs.orderedListOption
        }
        app.tables.staticTexts[listType].tap()
        
        return self
    }
    
    func addListWithLines(type: String, lines: Array<String>) -> EditorPage {
        addList(type: type)

        let returnButton = app.buttons["Return"]
        for (index, line) in lines.enumerated() {
            enterText(text: line)
            if index != (lines.count - 1) {
                returnButton.tap()
            }
        }
        return self
    }
    
    /**
     Tapping on toolbar button. And swipes if needed.
     */
    @discardableResult
    func toolbarButtonTap(locator: String) -> EditorPage {
        let elementsQuery = app.scrollViews.otherElements
        let button = elementsQuery.buttons[locator]
        let swipeElement = elementsQuery.buttons[elementStringIDs.mediaButton].isHittable ? elementsQuery.buttons[elementStringIDs.mediaButton] : elementsQuery.buttons[elementStringIDs.linkButton]
        
        if !button.exists || !button.isHittable {
            swipeElement.swipeLeft()
        }
        Logger.log(message: "Tapping on Toolbar button: \(locator)", event: .d)
        button.tap()
        
        return self
    }
    
    /**
    Tapping in to textView by specific coordinate. Its always tricky to know what cooridnates to click.
     Here is a list of "known" coordinates:
     30:32 - first word in 2d indented line (list)
     30:72 - first word in 3d intended line (blockquote)
    */
    func tapByCordinates(x: Int, y: Int) -> EditorPage {
        // textView frames on different devices:
        // iPhone X (0.0, 88.0, 375.0, 391.0)
        // iPhone SE (0.0, 64.0, 320.0, 504.0)
        let frame = textView.frame
        var vector = CGVector(dx: frame.minX + CGFloat(x), dy: frame.minY + CGFloat(y))
        if frame.minY == 88 {
            let yDiff = frame.minY - 64 // 64 - is minY for "normal" devices
            vector = CGVector(dx: frame.minX + CGFloat(x), dy: frame.minY - yDiff + CGFloat(y))
        }
        
        textView.coordinate(withNormalizedOffset:CGVector.zero).withOffset(vector).tap()
        sleep(1) // to make sure that "paste" manu wont show up.
        return self
    }
    
    /**
     Switches between Rich and HTML view.
     */
    func switchContentView() -> EditorPage {
        toolbarButtonTap(locator: elementStringIDs.sourcecodeButton)
        return EditorPage(mode: mode.toggle())
    }
    
    /**
     Common method to type in different text fields
     */
    @discardableResult
    func enterText(text: String) -> EditorPage {
        textView.typeText(text)
        return self
    }
    
    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    func enterTextInTitle(text: String) -> Void {
        app.textFields[titleTextField].typeText(text)
    }

    @discardableResult
    func deleteText(chars: Int) -> EditorPage {
        for _ in 1...chars {
            app.keys["delete"].tap()
        }

        return self
    }
    
    func gotoRootPage() -> BlogsPage {
        app.navigationBars["AztecExample.EditorDemo"].buttons["Root View Controller"].tap()
        return BlogsPage()
    }
    
    func getViewContent() -> String {
        if mode == .rich {
            return getTextContent()
        }
        
        return getHTMLContent()
    }
    
    /**
     Selects all entered text in provided textView element
     */
    func selectAllText() -> EditorPage {
        textView.coordinate(withNormalizedOffset:CGVector.zero).press(forDuration: 1)

        app.menuItems["Select All"].tap()
        
        return self
    }
    
    func makeLink() -> EditLinkPage {
        toolbarButtonTap(locator: elementStringIDs.linkButton)
        
        return EditLinkPage()
    }
    /*
     Select Image from Camera Roll by its ID. Starts with 0
     Simulator range: 0..4
    */
    func addImageByOrder(id: Int) -> EditorPage {
        toolbarButtonTap(locator: elementStringIDs.mediaButton)
        let cameraRollButton = XCUIApplication().otherElements.cells["Camera Roll"]
        waitFor(element: cameraRollButton, predicate: "isEnabled == true && isHittable == true")
        cameraRollButton.tap()

        // Wait for the Camera Roll Animation
        let navigationBar = XCUIApplication().otherElements.navigationBars["Camera Roll"]
        _ = navigationBar.waitForExistence(timeout: waitTimeout)

        // Inject the first picture
        XCUIApplication().cells.element(boundBy: 0).tap()

        // wait for upload simulation
        sleep(6)

        return self
    }
    
    private func getHTMLContent() -> String {
        let text = textView.value as! String
        
        // Remove spaces between HTML tags.
        let regex = try! NSRegularExpression(pattern: ">\\s+?<", options: .caseInsensitive)
        let range = NSMakeRange(0, text.count)
        let strippedText = regex.stringByReplacingMatches(in: text, options: .reportCompletion, range: range, withTemplate: "><")
        
        return strippedText
    }
    
    private func getTextContent() -> String {
        return textView.value as! String
    }
}

