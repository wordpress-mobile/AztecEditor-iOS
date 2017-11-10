//
//  HighPriorityIssuesTests.swift
//  AztecUITests
//
//  Created by brbrr on 11/10/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest

class HighPriorityIssuesTests: XCTestCase {
        
    private var app: XCUIApplication!
    private var richTextField: XCUIElement!
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIDevice.shared().orientation = .portrait
        app = XCUIApplication()
        app.launch()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts[elementStringIDs.emptyDemo].tap()
        
        let richTextField = app.textViews[elementStringIDs.richTextField]
        richTextField.tap()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Gihtub issue #393
    func testLongTitle() {
        //    Title line height is about 22px, so it might be useing for comparing the height difference should make it precise.
        //    But may be fragile due to different font sizes etc
        let titleLineHeight = 22
        
        let titleTextView = app.textViews[elementStringIDs.titleTextField]
        titleTextView.tap()
        
        let oneLineTitleHeight = Int(titleTextView.frame.height)
        
        titleTextView.typeText("very very very very very very long title in a galaxy not so far away")
        let twoLineTitleHeight = Int(titleTextView.frame.height)
        XCTAssert(twoLineTitleHeight - oneLineTitleHeight == titleLineHeight )
        //        XCTAssert(oneLineTitleHeight < twoLineTitleHeight)
    }
    
    func testNewlinesInTitle() {
        //    Title line height is about 22px, so it might be useing for comparing the height difference should make it precise.
        //    But may be fragile due to different font sizes etc
        let titleLineHeight = 22
        
        let titleTextView = app.textViews[elementStringIDs.titleTextField]
        titleTextView.tap()
        
        titleTextView.typeText("line 1")
        let oneLineTitleHeight = Int(titleTextView.frame.height)
        
        titleTextView.typeText("\nline 2")
        let twoLineTitleHeight = Int(titleTextView.frame.height)
        XCTAssert(twoLineTitleHeight - oneLineTitleHeight == titleLineHeight )
        //        XCTAssert(oneLineTitleHeight < twoLineTitleHeight)
        
        titleTextView.typeText("\nline 3")
        let threeLineTitleHeight = Int(titleTextView.frame.height)
        XCTAssert(threeLineTitleHeight - twoLineTitleHeight == titleLineHeight )
        //        XCTAssert(twoLineTitleHeight < threeLineTitleHeight)
    }
    
}


