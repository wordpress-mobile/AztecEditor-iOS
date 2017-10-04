//
//  CameraRollPage.swift
//  AztecExample
//
//  Created by Matisse Hack on 8/28/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest
import VSMobileCenterExtensions

class CameraRollPage: BasePage {
    
    private var firstPhoto: XCUIElement!
    
    override var Trait: XCUIElement! {
        return app.navigationBars["Camera Roll"]
    }
    
    @discardableResult
    override init() {
        super.init()
        
        firstPhoto = app.collectionViews["PhotosGridView"].cells.element(boundBy: 0)
    }
    
    func chooseFirstPhoto() {
        firstPhoto.tap()
        MCLabel.labelStep("Chose first photo")
    }
}
