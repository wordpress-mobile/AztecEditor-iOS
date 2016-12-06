import Foundation
import UIKit

class Blockquote: NSObject, NSCoding {
    public func encode(with aCoder: NSCoder) {

    }

    override public init() {

    }

    required public init?(coder aDecoder: NSCoder){

    }
}

struct BlockquoteFormatter: ParagraphAttributeFormatter {
    let attributes: [String: AnyObject] = {
        let style = ParagraphStyle()
        style.headIndent = Metrics.defaultIndentation
        style.firstLineHeadIndent = style.headIndent
        style.tailIndent = -Metrics.defaultIndentation
        style.paragraphSpacing = Metrics.defaultIndentation
        style.paragraphSpacingBefore = Metrics.defaultIndentation
        style.blockquote = Blockquote()

        return [
            NSParagraphStyleAttributeName: style            
        ]
    }()

    func present(inAttributes attributes: [String : AnyObject]) -> Bool {
        if let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle {
            return paragraphStyle.blockquote != nil
        }
        return false
    }
}

