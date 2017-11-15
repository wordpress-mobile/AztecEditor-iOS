import Foundation
import UIKit

#if swift(>=4.0)
    public typealias AttributedStringKey = NSAttributedStringKey
    
    public extension AttributedStringKey {
        public init(key: String) {
            self.init(key)
        }
    }
#else
    public typealias AttributedStringKey = String
    
    public extension AttributedStringKey {
        public init(key: String) {
            self.init(stringLiteral: key)
        }

        public static let attachment = NSAttachmentAttributeName
        public static let backgroundColor = NSBackgroundColorAttributeName
        public static let baselineOffset = NSBaselineOffsetAttributeName
        public static let expansion = NSExpansionAttributeName
        public static let font = NSFontAttributeName
        public static let foregroundColor = NSForegroundColorAttributeName
        public static let kern = NSKernAttributeName
        public static let ligature = NSLigatureAttributeName
        public static let link = NSLinkAttributeName
        public static let obliqueness = NSObliquenessAttributeName
        public static let paragraphStyle = NSParagraphStyleAttributeName
        public static let shadow = NSShadowAttributeName
        public static let strikethroughColor = NSStrikethroughColorAttributeName
        public static let strikethroughStyle = NSStrikethroughStyleAttributeName
        public static let strokeColor = NSStrokeColorAttributeName
        public static let strokeWidth = NSStrokeWidthAttributeName
        public static let textEffect = NSTextEffectAttributeName
        public static let underlineColor = NSUnderlineColorAttributeName
        public static let underlineStyle = NSUnderlineStyleAttributeName
        public static let verticalGlyphForm = NSVerticalGlyphFormAttributeName
        public static let writingDirection = NSWritingDirectionAttributeName
    }
#endif
