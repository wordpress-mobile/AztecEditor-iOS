//
//  BlogsPage.swift
//  AztecUITests
//
//  Created by brbrr on 11/13/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import Foundation
import XCTest

class EditorPage: BasePage {
    
    var textField: String!
    var type: String!
    var textView: XCUIElement!

    private var titleTextField = "Title"
    private var richTextField = "richContentView"
    private var htmlTextField = "HTMLContentView"

    init(appInstance: XCUIApplication, type: String) {
        textField = ""
        self.type = type
        switch type {
        case "rich":
            textField = richTextField
        case "html":
            textField = htmlTextField
        default:
            textField = "invalid locator. check Editor.init type param"
        }
        textView = appInstance.textViews[textField]
        super.init(appInstance: appInstance, element: textView)
      
        showOptionsStrip()
    }
    
    func showOptionsStrip() -> Void {
//        app.textViews[textField].tap()
        textView.tap()
        expandOptionsSctrip()
    }
    
    func expandOptionsSctrip() -> Void {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        
        if expandButton.exists && expandButton.isHittable {
            expandButton.tap()
        }
    }
    
    func switchContentView() -> EditorPage {
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.buttons[elementStringIDs.mediaButton].swipeLeft()
        elementsQuery.buttons[elementStringIDs.sourcecodeButton].tap()
        
        let newType = type == "rich" ? "html" : "rich"
        return EditorPage.init(appInstance: app, type: newType)
    }
    
    /**
     Common method to type in different text fields
     */
    func enterText(text: String) -> EditorPage {
//        app.textViews[textField].typeText(text)
        textView.typeText(text)
        return self
    }
    
    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    func enterTextInTitle(text: String) -> Void {
        app.textViews[titleTextField].typeText(text)
    }
    
    func gotoRootPage() -> BlogsPage {
        app.navigationBars["AztecExample.EditorDemo"].buttons["Root View Controller"].tap()
        return BlogsPage.init(appInstance: app)
    }
    
    func getViewContent() -> String {
        if  type == "rich" {
            return getTextContent()
        }
        
        return getHTMLContent()
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
        let text = textView.value as! String
        return text
    }
}

