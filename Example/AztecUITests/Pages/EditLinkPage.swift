import Foundation
import XCTest

class EditLinkPage: BasePage {
    var linkModal: XCUIElement
    var urlTextField: XCUIElement
    var nameTextField: XCUIElement
    var cancelButton: XCUIElement
    var insertButton: XCUIElement
    var removeButton: XCUIElement

    init() {
        let app = XCUIApplication()
        linkModal = app.alerts["linkModal"] // app.alerts["Insert Link"]
//        if !linkModal.exists && app.alerts["Update Link"].exists {
//            linkModal = app.alerts["Update Link"]
//        }
        
        urlTextField = linkModal.collectionViews.textFields["linkModalURL"]
        nameTextField = linkModal.collectionViews.textFields["linkModalText"]
        cancelButton = linkModal.buttons["Cancel"]
        insertButton = linkModal.buttons["insertLinkButton"]
        removeButton = linkModal.buttons["Remove Link"]
        
//        clearURLTextField = urlTextField.buttons["Clear text"].tap()
//        clearNameTextField = nameTextField.buttons["Clear text"].tap()

        super.init(element: linkModal)
    }
    
    func updateURL(url: String) -> EditLinkPage {
        urlTextField.tap()
        urlTextField.replaceText(text: url)
        return self
    }
    
    func updateName(text: String) -> EditLinkPage {
        nameTextField.tap()
        nameTextField.replaceText(text: text)
        return self
    }
    
    func ok() -> EditorPage {
        insertButton.tap()
        
        return EditorPage.init(type: "rich")
    }
    
    func cancel() -> EditorPage {
        cancelButton.tap()
        
        return EditorPage.init(type: "rich")
    }
    
    func remove() -> EditorPage {
        removeButton.tap()
        
        return EditorPage.init(type: "rich")
    }

}
