//
//  BaseTest.swift
//  AztecExample
//
//  Created by Matisse Hack on 8/7/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest
import VSMobileCenterExtensions

class BaseTest : XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
        
        RootPage()
            .chooseEmptyEditor()
    }
    
    override func tearDown() {
        super.tearDown()
        app.terminate()
    }
}
