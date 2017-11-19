//
//  BlogsPage.swift
//  AztecUITests
//
//  Created by brbrr on 11/13/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import Foundation
import XCTest


class BlogsPage {
    
    private var app: XCUIApplication!
    
    init(appInstance: XCUIApplication) {
        app = appInstance
    }
    
    func gotoEmptyDemo() {
        app.tables.staticTexts[elementStringIDs.emptyDemo].tap()
        
        showOptionsStrip()
    }
    
    func gotoDemo() {
        app.tables.staticTexts[elementStringIDs.demo].tap()
        
        showOptionsStrip()
    }
    
    func showOptionsStrip() -> Void {
        app.textViews[elementStringIDs.richTextField].tap()
        expandOptionsSctrip()
    }
    
    func expandOptionsSctrip() -> Void {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        
        if expandButton.exists && expandButton.isHittable {
            expandButton.tap()
        }
    }
}
