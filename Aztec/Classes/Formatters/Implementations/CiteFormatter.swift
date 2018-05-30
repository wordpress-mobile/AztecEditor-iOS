import Foundation
import UIKit

class CiteFormatter: FontFormatter {

//    var placeholderAttributes: [NSAttributedStringKey: Any]?
//
//    let htmlRepresentationKey: NSAttributedStringKey

    // MARK: - Init

    init() {
        super.init(traits: .traitItalic, htmlRepresentationKey: .citeHtmlRepresentation)
    }

//    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
//        return range
//    }
//
//    func worksInEmptyRange() -> Bool {
//        return false
//    }
//
//    func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {
//        var resultingAttributes = attributes
//
//        resultingAttributes[.font] = monospaceFont
//        resultingAttributes[.backgroundColor] = self.backgroundColor
//        var representationToUse = HTMLRepresentation(for: .element(HTMLElementRepresentation.init(name: "cite", attributes: [])))
//        if let requestedRepresentation = representation {
//            representationToUse = requestedRepresentation
//        }
//        resultingAttributes[htmlRepresentationKey] = representationToUse
//
//        return resultingAttributes
//    }
//
//    func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
//        var resultingAttributes = attributes
//
//        resultingAttributes.removeValue(forKey: .font)
//        resultingAttributes.removeValue(forKey: .backgroundColor)
//        resultingAttributes.removeValue(forKey: htmlRepresentationKey)
//
//        if let placeholderAttributes = self.placeholderAttributes {
//            resultingAttributes[.font] = placeholderAttributes[.font]
//            resultingAttributes[.backgroundColor] = placeholderAttributes[.backgroundColor]
//        }
//
//        return resultingAttributes
//    }
//
//    func present(in attributes: [NSAttributedStringKey: Any]) -> Bool {
//        return attributes[NSAttributedStringKey.codeHtmlRepresentation] != nil
//    }
}


