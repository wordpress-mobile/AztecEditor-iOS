import Foundation
import UIKit

open class ParagraphStyle: NSMutableParagraphStyle {

    var textList: TextList?
    var blockquote: Blockquote?

    override init() {
        textList = nil
        blockquote = nil
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        textList = nil
        blockquote = nil
        if aDecoder.containsValue(forKey: String(describing: TextList.self)) {
            let styleRaw = aDecoder.decodeInteger(forKey: String(describing: TextList.self))
            if let style = TextList.Style(rawValue:styleRaw) {
                textList = TextList(style: style)
            }
        }
        if aDecoder.containsValue(forKey: String(describing:Blockquote.self)) {
            blockquote = aDecoder.decodeObject(forKey: String(describing:Blockquote.self)) as? Blockquote            
        }
        super.init(coder: aDecoder)
    }

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        if let textListSet = textList {
            aCoder.encode(textListSet.style.rawValue, forKey: String(describing: TextList.self))
        }

        if let blockquote = self.blockquote {
            aCoder.encode(blockquote, forKey: String(describing:Blockquote.self))
        }
    }

    override open func setParagraphStyle(_ obj: NSParagraphStyle) {
        if let paragrahStyle = obj as? ParagraphStyle {
            textList = paragrahStyle.textList
            blockquote = paragrahStyle.blockquote
        }
        super.setParagraphStyle(obj)
    }

    private static let tabStepInterval = 8
    private static let tabStepCount    = 12
    
    open override class var `default`: NSParagraphStyle {
        let style = ParagraphStyle()

        var tabStops = [NSTextTab]()

        for intervalNumber in (1 ..< tabStepCount) {
            let location = intervalNumber * tabStepInterval
            let textTab = NSTextTab(textAlignment: .natural, location: CGFloat(location), options: [:])

            tabStops.append(textTab)
        }

        style.tabStops = tabStops

        return style
    }

    class var defaultList : ParagraphStyle {
        let style = ParagraphStyle()
        style.setParagraphStyle(self.default)

        style.headIndent = 12
        style.firstLineHeadIndent = style.headIndent        
        return style
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let otherParagraph = object as? ParagraphStyle else {
            return false
        }

        if textList != otherParagraph.textList {
            return false
        }

        if blockquote != otherParagraph.blockquote {
            return false
        }


        return super.isEqual(object)
    }

    static func ==(lhs: ParagraphStyle, rhs: ParagraphStyle) -> Bool {
        return lhs.isEqual(rhs)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let result = super.copy(with: zone)
        let thisResult = ParagraphStyle()
        thisResult.setParagraphStyle(result as! NSParagraphStyle)
        thisResult.textList = textList
        thisResult.blockquote = blockquote
        return thisResult
    }

    open override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let result = super.mutableCopy(with: zone)
        let thisResult = ParagraphStyle()
        thisResult.setParagraphStyle(result as! NSParagraphStyle)
        thisResult.textList = textList
        thisResult.blockquote = blockquote
        return thisResult
    }

    var debugString: String {
        return description
    }

    open override var description:String {
        return super.description + "\nTextList:\(textList?.style)\nBlockquote:\(blockquote)"
    }
}
