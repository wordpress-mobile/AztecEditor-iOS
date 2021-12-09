import Foundation
import UIKit

class MarkFormatter: AttributeFormatter {

    var placeholderAttributes: [NSAttributedString.Key: Any]?

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
       var resultingAttributes = attributes

        var representationToUse = HTMLRepresentation(for: .element(HTMLElementRepresentation.init(name: "mark", attributes: [])))
        if let requestedRepresentation = representation {
            representationToUse = requestedRepresentation
        }
        resultingAttributes[.markHtmlRepresentation] = representationToUse

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = attributes

        resultingAttributes.removeValue(forKey: .markHtmlRepresentation)

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        return attributes[NSAttributedString.Key.markHtmlRepresentation] != nil
    }
}
