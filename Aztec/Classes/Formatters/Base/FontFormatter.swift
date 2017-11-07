import Foundation
import UIKit

class FontFormatter: AttributeFormatter {

    var placeholderAttributes: [NSAttributedStringKey: Any]? { return nil }
    
    let htmlRepresentationKey: NSAttributedStringKey
    let traits: UIFontDescriptorSymbolicTraits

    init(traits: UIFontDescriptorSymbolicTraits, htmlRepresentationKey: NSAttributedStringKey) {
        self.htmlRepresentationKey = htmlRepresentationKey
        self.traits = traits
    }

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }

    func worksInEmptyRange() -> Bool {
        return false
    }

    func apply(to attributes: [NSAttributedStringKey: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedStringKey: Any] {

        guard let font = attributes[.font] as? UIFont else {
            return attributes
        }

        let newFont = font.modifyTraits(traits, enable: true)

        var resultingAttributes = attributes

        resultingAttributes[.font] = newFont
        resultingAttributes[htmlRepresentationKey] = representation

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedStringKey: Any]) -> [NSAttributedStringKey: Any] {
        var resultingAttributes = attributes
        guard let font = attributes[.font] as? UIFont else {
            return attributes
        }

        let newFont = font.modifyTraits(traits, enable: false)
        resultingAttributes[.font] = newFont
        
        resultingAttributes.removeValue(forKey: htmlRepresentationKey)

        return resultingAttributes
    }

    func present(in attributes: [NSAttributedStringKey : Any]) -> Bool {
        guard let font = attributes[.font] as? UIFont else {
            return false
        }
        let enabled = font.containsTraits(traits)
        return enabled
    }
}

