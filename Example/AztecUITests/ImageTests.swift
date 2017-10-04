//
//  ImageTests.swift
//  AztecExample
//
//  Created by Matisse Hack on 8/7/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest

class ImageTests: BaseTest  {
    
    func testAddPhoto() {
        
        addUIInterruptionMonitor(withDescription: "Photo permission dialogue") { (alert) -> Bool in
            alert.buttons["OK"].tap()
            return true
        }
        
        var sampleText = "sample text "
        
        for _ in 1...5 {
            sampleText += sampleText
        }
        
        EditorPage()
            .tapTop()
            .insertText(text: sampleText)
            .tapTop()
            .insertMedia()
        
        PhotosPage()
            .chooseCameraRoll()
        
        CameraRollPage()
            .chooseFirstPhoto()
        
        let regex = "<p>.+<img src=.+>.+<\\/p>"
        
        EditorPage()
            .toggleHtml()
            .verifyEditorContents(expectedRegex: regex)
    }
    
    func testAddTwoPhotos() {
        
        addPhotoWithHTML()
        
        EditorPage()
            .insertMedia()
        
        PhotosPage()
            .chooseCameraRoll()
        
        CameraRollPage()
            .chooseFirstPhoto()
        
        let regex = "<p>.*<img src=.+>.*<img src=.+>.*<\\/p>"
        
        EditorPage()
            .toggleHtml()
            .verifyEditorContents(expectedRegex: regex)
    }
    
    func testEditPhoto() {
        
        addPhotoWithHTML()
        
        EditorPage()
            .tapTop()
            .tapTop()
            .openMediaDetails()
        
        MediaDetailsPage()
            .choose(size: MediaDetailsPage.SizeStyle.Medium)
            .choose(alignment: MediaDetailsPage.AlignmentStyle.Left)
            .done()
        
        EditorPage()
    }
    
    func addPhotoWithHTML() {
        
        let imageHtml = "<p><img src=\"https://examplebloge.files.wordpress.com/2017/02/3def4804-d9b5-11e6-88e6-d7d8864392e0.png\"></p>"
        
        EditorPage()
            .tapTop()
            .toggleHtml()
            .insertHTML(html: imageHtml)
            .toggleHtml()
    }
}
