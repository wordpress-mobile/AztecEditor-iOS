//
//  FormattingTests.swift
//  AztecExample
//
//  Created by Matisse Hack on 8/31/17.
//  Copyright © 2017 Automattic Inc. All rights reserved.
//

import XCTest

class FormattingTests: BaseTest  {
    
    // When the app is first installed the overflow toolbar items aren't shown
    // This test runs before all others
    func testA() {
        EditorPage()
            .tapTop()
            .toggleOverflow()
    }
    
    func testSimpleBoldText() {
        
        let expected = "<p><strong>some text</strong></p>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeBold()
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testSimpleItalicText() {
        
        let expected = "<p><em>some text</em></p>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeItalics()
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testSimpleUnderlineText() {
        
        let expected = "<p><u>some text</u></p>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeUnderline()
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testSimpleStrikethroughText() {
        
        let expected = "<p><strike>some text</strike></p>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeStrikethrough()
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testSimpleBlockquoteText() {
        
        let expected = "<blockquote>some text</blockquote>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeQuote()
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
     func testSimpleUnorderedListText() {
        
        let expected = "<ul>\n  <li>some text</li>\n</ul>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeList(style: EditorPage.ListStyle.Unordered)
            .toggleHtml()
            .verifyEditorContents(expected: expected)
     }
    
     func testSimpleOrderedListText() {
        
        let expected = "<ol>\n  <li>some text</li>\n</ol>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeList(style: EditorPage.ListStyle.Ordered)
            .toggleHtml()
            .verifyEditorContents(expected: expected)
     }
    
    func testSimpleLinkedText() {
        
        let link = "https://wordpress.com/"
        let expected = "<p><a href=\"\(link)\">some text</a></p>"
        
        UIPasteboard.general.string = link
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeLink()
        
        EditLinkPage()
            .insert()
        
        EditorPage()
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testHorizontalRuler() {
        
        let expected = "<p>\n  <hr>\n</p>"
        
        EditorPage()
            .tapTop()
            .addHorizontalRule()
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testHorizontalRulerWithText() {
        
        let expected = "<p>some</p>\n<p>\n  <hr>\n</p>\n<p>text</p>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some\n")
            .addHorizontalRule()
            .insertText(text: "\ntext")
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testMoreTag() {
        
        let expected = "<p><!--more--></p>"
        
        EditorPage()
            .tapTop()
            .addMoreRule()
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testMoreTagWithText() {
        
        let expected = "<p>some</p>\n<p><!--more--></p>\n<p>text</p>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some\n")
            .addMoreRule()
            .insertText(text: "\ntext")
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testHeadingOneText() {
        
        let expected = "<h1>some text</h1>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeHeader(style: EditorPage.HeadingStyle.One)
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testHeadingTwoText() {
        
        let expected = "<h2>some text</h2>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeHeader(style: EditorPage.HeadingStyle.Two)
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testHeadingThreeText() {
        
        let expected = "<h3>some text</h3>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeHeader(style: EditorPage.HeadingStyle.Three)
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testHeadingFourText() {
        
        let expected = "<h4>some text</h4>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeHeader(style: EditorPage.HeadingStyle.Four)
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testHeadingFiveText() {
        
        let expected = "<h5>some text</h5>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeHeader(style: EditorPage.HeadingStyle.Five)
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testHeadingSixText() {
        
        let expected = "<h6>some text</h6>"
        
        EditorPage()
            .tapTop()
            .insertText(text: "some text")
            .selectAllText()
            .makeHeader(style: EditorPage.HeadingStyle.Six)
            .toggleHtml()
            .verifyEditorContents(expected: expected)
    }
    
    func testMixedList() {
        
        var sampleText = "sample text\n"
        let expected1 = "<ul>[\\S\\s]+</ul>"
        let expected2 = "<ul>[\\S\\s]+</ul>\n<ol>[\\S\\s]+</ol>\n<ul>[\\S\\s]+</ul>"
        
        for _ in 1...4 {
            sampleText += sampleText
        }
        
        EditorPage()
            .tapTop()
            .insertText(text: sampleText)
            .selectAllText()
            .makeList(style: EditorPage.ListStyle.Unordered)
            .toggleHtml()
            .verifyEditorContents(expectedRegex: expected1)
            .toggleHtml()
            .tapTop()
            .tapTop()
            .makeList(style: EditorPage.ListStyle.Ordered)
            .toggleHtml()
            .verifyEditorContents(expectedRegex: expected2)
    }
}
