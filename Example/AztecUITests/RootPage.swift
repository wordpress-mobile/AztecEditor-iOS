//
//  RootPage.swift
//  AztecExample
//
//  Created by Matisse Hack on 8/7/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest
import VSMobileCenterExtensions

class RootPage: BasePage {
    
    private var editorDemo: XCUIElement!
    private var emptyEditorDemo: XCUIElement!
    
    override var Trait: XCUIElement! {
        return app.navigationBars["Root View Controller"].staticTexts["Root View Controller"]
    }
    
    @discardableResult
    override init() {
        super.init()
        
        editorDemo = app.staticTexts["Editor Demo"]
        emptyEditorDemo = app.staticTexts["Empty Editor Demo"]
    }
    
    func chooseFullEditor() {
        editorDemo.tap()
        MCLabel.labelStep("Opening editor demo")
    }
    
    func chooseEmptyEditor() {
        emptyEditorDemo.tap()
        MCLabel.labelStep("Opening empty editor demo")
    }
}
