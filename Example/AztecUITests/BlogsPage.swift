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
        
        let richTextField = app.textViews[elementStringIDs.richTextField]
        richTextField.tap()
    }
    
    func gotoDemo() {
        app.tables.staticTexts[elementStringIDs.demo].tap()
        
        let richcontentviewTextView = app.textViews[elementStringIDs.richTextField]
        richcontentviewTextView.tap()
    }
}
