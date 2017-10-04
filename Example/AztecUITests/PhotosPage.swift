//
//  PhotosPage.swift
//  AztecExample
//
//  Created by Matisse Hack on 8/9/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest
import VSMobileCenterExtensions

class PhotosPage: BasePage {
    
    private var cancelButton: XCUIElement!
    private var cameraRollButton: XCUIElement!
    
    override var Trait: XCUIElement! {
        return app.navigationBars["Photos"]
    }
    
    @discardableResult
    override init() {
        super.init()
        
        cancelButton = app.buttons["Cancel"]
        cameraRollButton = app.buttons["Camera Roll"]
    }
    
    func chooseCameraRoll() {
        cameraRollButton.tap()
        MCLabel.labelStep("Chose camera roll")
    }
}
