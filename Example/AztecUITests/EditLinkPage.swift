//
//  EditLinkPage.swift
//  AztecExample
//
//  Created by Matisse Hack on 9/5/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest
import VSMobileCenterExtensions

class EditLinkPage: BasePage {
    
    private var urlField: XCUIElement!
    private var nameField: XCUIElement!
    private var insertButton: XCUIElement!
    private var updateButton: XCUIElement!
    private var removeButton: XCUIElement!
    private var cancelButton: XCUIElement!
    
    override var Trait: XCUIElement! {
        return app.alerts.element
    }
    
    @discardableResult
    override init() {
        super.init()
        
        urlField = app.textFields["URL"]
        nameField = app.textFields["Link Name"]
        insertButton = app.buttons["Insert Link"]
        updateButton = app.buttons["Update Link"]
        removeButton = app.buttons["Remove Link"]
        cancelButton = app.buttons["Cancel"]
    }
    
    @discardableResult
    func update(url: String) -> EditLinkPage {
        urlField.tap()
        urlField.typeText(url)
        MCLabel.labelStep("Entered url")
        
        return self
    }
    
    @discardableResult
    func update(name: String) -> EditLinkPage {
        nameField.tap()
        nameField.typeText(name)
        MCLabel.labelStep("Entered name")
        
        return self
    }
    
    func insert() {
        insertButton.tap()
        MCLabel.labelStep("Inserted link")
    }
    
    func update() {
        updateButton.tap()
        MCLabel.labelStep("Updated link")
    }
    
    func remove() {
        removeButton.tap()
        MCLabel.labelStep("Removed link")
    }
    
    func cancel() {
        cancelButton.tap()
        MCLabel.labelStep("Canceled")
    }
}
