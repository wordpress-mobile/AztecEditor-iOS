//
//  EditorPage.swift
//  AztecExample
//
//  Created by Matisse Hack on 8/7/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import Foundation
import XCTest
import VSMobileCenterExtensions

class EditorPage: BasePage {
    
    private var backButton: XCUIElement!
    
    private var editor: XCUIElement!
    private var htmlEditor: XCUIElement!
    
    private var insertMediaButton: XCUIElement!
    private var headingButton: XCUIElement!
    private var listButton: XCUIElement!
    private var quoteButton: XCUIElement!
    private var boldButton: XCUIElement!
    private var italicsButton: XCUIElement!
    private var linkButton: XCUIElement!
    private var underlineButton: XCUIElement!
    private var strikethroughButton: XCUIElement!
    private var horizontalRuleButton: XCUIElement!
    private var moreRuleButton: XCUIElement!
    private var htmlButton: XCUIElement!
    private var overflowToggleButton: XCUIElement!
    private var subOptionsTable: XCUIElement!
    
    private var selectButton: XCUIElement!
    private var selectAllButton: XCUIElement!
    private var pasteButton: XCUIElement!
    private var styleButton: XCUIElement!
    private var pasteAndMatchButton: XCUIElement!
    
    private var mediaDetailsButton: XCUIElement!
    
    override var Trait: XCUIElement! {
        return app.navigationBars["Root View Controller"].buttons["Root View Controller"]
    }
    
    @discardableResult
    override init() {
        super.init()
        
        backButton = app.navigationBars["AztecExample.EditorDemo"].buttons["Root View Controller"]
        
        editor = app.textViews["richContentView"]
        htmlEditor = app.textViews["HTMLContentView"]
        
        insertMediaButton = app.buttons["formatToolbarInsertMedia"]
        headingButton = app.buttons["formatToolbarSelectParagraphStyle"]
        listButton = app.buttons["formatToolbarToggleListUnordered"]
        quoteButton = app.buttons["formatToolbarToggleBlockquote"]
        boldButton = app.buttons["formatToolbarToggleBold"]
        italicsButton = app.buttons["formatToolbarToggleItalic"]
        linkButton = app.buttons["formatToolbarInsertLink"]
        underlineButton = app.buttons["formatToolbarToggleUnderline"]
        strikethroughButton = app.buttons["formatToolbarToggleStrikethrough"]
        horizontalRuleButton = app.buttons["formatToolbarInsertHorizontalRuler"]
        moreRuleButton = app.buttons["formatToolbarInsertMore"]
        htmlButton = app.buttons["formatToolbarToggleHtmlView"]
        overflowToggleButton = app.buttons["formatToolbarOverflowToggle"]
        subOptionsTable = app.tables.element
        
        selectButton = app.menuItems["Select"]
        selectAllButton = app.menuItems["Select All"]
        pasteButton = app.menuItems["Paste"]
        styleButton = app.menuItems["Style options"]
        pasteAndMatchButton = app.menuItems["Paste and Match Style"]
        
        mediaDetailsButton = app.sheets["Media Options"].buttons["Media Details"]
    }
    
    func goBack() {
        backButton.tap()
        MCLabel.labelStep("Going back")
    }
    
    @discardableResult
    func tapTop() -> EditorPage {
        let frame = editor.frame
        editor
            .coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: frame.midX, dy: frame.height * 0.2))
            .tap()
        MCLabel.labelStep("Tapped top of editor")
        
        return self
    }
    
    @discardableResult
    func selectAllText() -> EditorPage {
        editor.tap()
        selectAllButton.tap()
        MCLabel.labelStep("Selected all text")
        
        return self
    }
    
    @discardableResult
    func insertText(text: String) -> EditorPage {
        editor.typeText(text)
        MCLabel.labelStep("Inserted text")
        
        return self
    }
    
    @discardableResult
    func insertHTML(html: String) -> EditorPage {
        htmlEditor.typeText(html)
        MCLabel.labelStep("Inserted HTML")
        
        return self
    }
    
    func insertMedia() {
        insertMediaButton.tap()
        MCLabel.labelStep("Inserting media")
    }
    
    func openMediaDetails() {
        mediaDetailsButton.tap()
        MCLabel.labelStep("Opened media details")
    }
    
    @discardableResult
    func makeHeader(style: HeadingStyle) -> EditorPage {
        headingButton.tap()
        MCLabel.labelStep("Choosing heading style")
        
        if style == .Five || style == .Six {
            subOptionsTable.swipeUp()
        }
        
        subOptionsTable.staticTexts[style.rawValue].tap()
        MCLabel.labelStep("Chose \(style.rawValue)")
        
        return self
    }
    
    @discardableResult
    func makeList(style: ListStyle) -> EditorPage {
        listButton.tap()
        MCLabel.labelStep("Choosing list style")
        subOptionsTable.staticTexts[style.rawValue].tap()
        MCLabel.labelStep("Chose \(style.rawValue)")
        
        return self
    }
    
    @discardableResult
    func makeQuote() -> EditorPage {
        quoteButton.tap()
        MCLabel.labelStep("Made quote")
        
        return self
    }
    
    @discardableResult
    func makeBold() -> EditorPage {
        boldButton.tap()
        MCLabel.labelStep("Made bold")
        
        return self
    }
    
    @discardableResult
    func makeItalics() -> EditorPage {
        italicsButton.tap()
        MCLabel.labelStep("Made italics")
        
        return self
    }
    
    func makeLink() {
        linkButton.tap()
        MCLabel.labelStep("Opened link dialogue")
    }
    
    @discardableResult
    func makeUnderline() -> EditorPage {
        underlineButton.tap()
        MCLabel.labelStep("Made underline")
        
        return self
    }
    
    @discardableResult
    func makeStrikethrough() -> EditorPage {
        strikethroughButton.tap()
        MCLabel.labelStep("Made strigkethrough")
        
        return self
    }
    
    @discardableResult
    func addHorizontalRule() -> EditorPage {
        horizontalRuleButton.tap()
        MCLabel.labelStep("Added horizontal rule")
        
        return self
    }
    
    @discardableResult
    func addMoreRule() -> EditorPage {
        moreRuleButton.tap()
        MCLabel.labelStep("Added more rule")
        
        return self
    }
    
    @discardableResult
    func toggleHtml() -> EditorPage {
        htmlButton.tap()
        MCLabel.labelStep("Toggled HTML")
        
        return self
    }
    
    @discardableResult
    func toggleOverflow() -> EditorPage {
        overflowToggleButton.tap()
        MCLabel.labelStep("Showing more formatting options")
        
        return self
    }
    
    @discardableResult
    func verifyEditorContents(expected: String) -> EditorPage {
        let text = htmlEditor.value as! String
        XCTAssertEqual(expected, text)
        MCLabel.labelStep("Verified expected editor contents")
        
        return self
    }
    
    @discardableResult
    func verifyEditorContents(expectedRegex: String) -> EditorPage {
        let text = htmlEditor.value as! String
        let match = text.range(of: expectedRegex, options: .regularExpression)
        XCTAssertNotNil(match, "Regex '\(expectedRegex)' does not match text '\(text)'")
        MCLabel.labelStep("Verified expected editor contents")
        
        return self
    }
    
    enum HeadingStyle: String {
        case Default = "Default"
        case One = "Heading 1"
        case Two = "Heading 2"
        case Three = "Heading 3"
        case Four = "Heading 4"
        case Five = "Heading 5"
        case Six = "Heading 6"
    }
    
    enum ListStyle: String {
        case Unordered = "Unordered List"
        case Ordered = "Ordered List"
    }
}
