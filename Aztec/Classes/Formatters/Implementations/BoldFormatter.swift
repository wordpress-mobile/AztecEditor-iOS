import UIKit

/// BoldFormatter uses 2 different mechanisms to apply the bold effect:
/// 1. Headings: Applies shadow effect because headings are already bold by default
/// 2. Other text: Applies bold font trait.
class BoldFormatter: AttributeFormatter {
    
    private enum Shadow {
        enum DefaultOffset {
            static let width: CGFloat = 0.65
            static let height: CGFloat = 0.0
        }
        
        static let blurRadiusNoBlur: CGFloat = 0.0
        static let defaultColor: UIColor = .black
        
        // Creates a no blur NSShadow instance with given offset values
        static func shadow(width: CGFloat = DefaultOffset.width,
                           height: CGFloat = DefaultOffset.height,
                           color: UIColor) -> NSShadow {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = Shadow.blurRadiusNoBlur
            shadow.shadowOffset = CGSize(width: width, height: height)
            shadow.shadowColor = color
            return shadow
        }
        
        // Calculate Shadow offset due to font size
        static func offset(with fontSize: CGFloat) -> CGFloat {
            if fontSize >= 22 {
                return 0.72
            } else if fontSize >= 20 && fontSize < 22 {
                return 0.68
            } else if fontSize >= 18 && fontSize < 20 {
                return 0.65
            } else if fontSize >= 16 && fontSize < 18 {
                return 0.62
            } else {
                return 0.6
            }
        }
    }
    
    private let htmlRepresentationKey: NSAttributedString.Key = .boldHtmlRepresentation
    private let boldFontFormatter = FontFormatter(traits: .traitBold, htmlRepresentationKey: .boldHtmlRepresentation)
    
    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        guard attributes[.headingRepresentation] != nil else {
            return boldFontFormatter.apply(to: attributes, andStore: representation)
        }
        
        var resultingAttributes = attributes
        
        if let font = resultingAttributes[.font] as? UIFont {
            //Calculate letter spacing and shadow offset with respect to the font size
            let shadowOffsetWidth = Shadow.offset(with: font.pointSize)
            resultingAttributes[.shadow] = Shadow.shadow(width: shadowOffsetWidth, color: shadowColor(from: attributes))
            resultingAttributes[.kern] = shadowOffsetWidth
        } else {
            resultingAttributes[.shadow] = Shadow.shadow(color: shadowColor(from: attributes))
            resultingAttributes[.kern] =  Shadow.DefaultOffset.width
        }
        
        resultingAttributes[.boldHtmlRepresentation] = representation
        
        return resultingAttributes
    }
    
    func remove(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard attributes[.headingRepresentation] != nil else {
            return boldFontFormatter.remove(from: attributes)
        }
        
        var resultingAttributes = attributes
        
        resultingAttributes.removeValue(forKey: .shadow)
        resultingAttributes.removeValue(forKey: .kern)
        resultingAttributes.removeValue(forKey: .boldHtmlRepresentation)
        
        return resultingAttributes
    }
    
    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        guard attributes[.headingRepresentation] != nil else {
            return boldFontFormatter.present(in: attributes)
        }

        return attributes[.shadow] != nil
    }
    
    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return range
    }
    
    private func shadowColor(from attributes: [NSAttributedString.Key: Any]) -> UIColor {
        if let color = attributes[.foregroundColor] as? UIColor {
            return color
        }
        return Shadow.defaultColor
    }
}
