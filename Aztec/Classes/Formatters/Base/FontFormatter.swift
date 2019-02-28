import Foundation
import UIKit

class FontFormatter: AttributeFormatter {
    
    let htmlRepresentationKey: NSAttributedString.Key
    let traits: UIFontDescriptor.SymbolicTraits

    init(traits: UIFontDescriptor.SymbolicTraits, htmlRepresentationKey: NSAttributedString.Key) {
        self.htmlRepresentationKey = htmlRepresentationKey
        self.traits = traits
    }

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {

        guard let font = attributes[.font] as? UIFont else {
            return attributes
        }

        let newFont = font.modifyTraits(traits, enable: true)

        var resultingAttributes = attributes

        resultingAttributes[.font] = newFont
        resultingAttributes[htmlRepresentationKey] = representation

        return resultingAttributes
    }

    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var resultingAttributes = attributes
        
        resultingAttributes.removeValue(forKey: htmlRepresentationKey)
        
        guard let font = attributes[.font] as? UIFont else {
            return resultingAttributes
        }

        let newFont = font.modifyTraits(traits, enable: false)
        resultingAttributes[.font] = newFont
        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key : Any]) -> Bool {
        guard let font = attributes[.font] as? UIFont else {
            return false
        }
        let enabled = font.containsTraits(traits)
        return enabled
    }
}

