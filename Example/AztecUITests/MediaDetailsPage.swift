//
//  MediaDetailsPage.swift
//  AztecExample
//
//  Created by Matisse Hack on 9/8/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest
import VSMobileCenterExtensions

class MediaDetailsPage: BasePage {
    
    private var doneButton: XCUIElement!
    
    override var Trait: XCUIElement! {
        return app.staticTexts["Properties"]
    }
    
    @discardableResult
    override init() {
        super.init()
        
        doneButton = app.buttons["Done"]
    }
    
    @discardableResult
    func choose(size: SizeStyle) -> MediaDetailsPage {
        app.buttons[size.rawValue].tap()
        MCLabel.labelStep("Chose size")
        
        return self
    }
    
    @discardableResult
    func choose(alignment: AlignmentStyle) -> MediaDetailsPage {
        app.buttons[alignment.rawValue].tap()
        MCLabel.labelStep("Chose alignment")
        
        return self
    }
    
    func done() {
        doneButton.tap()
        MCLabel.labelStep("Chose alignment")
    }
    
    enum SizeStyle: String {
        case Thumbnail = "Thumbnail"
        case Medium = "Medium"
        case Large = "Large"
        case Full = "Full"
    }
    
    enum AlignmentStyle: String {
        case None = "None"
        case Left = "Left"
        case Center = "Center"
        case Right = "Right"
    }
}
