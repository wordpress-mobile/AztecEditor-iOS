import Foundation
import UIKit

open class ParagraphStyle: NSMutableParagraphStyle {

    private enum EncodingKeys: String {
        case headerLevel
    }

    var textList: TextList?
    var blockquote: Blockquote?
    var headerLevel: Int = 0

    override init() {
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        if aDecoder.containsValue(forKey: String(describing: TextList.self)) {
            let styleRaw = aDecoder.decodeInteger(forKey: String(describing: TextList.self))
            if let style = TextList.Style(rawValue:styleRaw) {
                textList = TextList(style: style)
            }
        }
        if aDecoder.containsValue(forKey: String(describing: Blockquote.self)) {
            blockquote = aDecoder.decodeObject(forKey: String(describing: Blockquote.self)) as? Blockquote
        }

        aDecoder.decodeInteger(forKey: EncodingKeys.headerLevel.rawValue)
        
        super.init(coder: aDecoder)
    }

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        if let textListSet = textList {
            aCoder.encode(textListSet.style.rawValue, forKey: String(describing: TextList.self))
        }

        if let blockquote = self.blockquote {
            aCoder.encode(blockquote, forKey: String(describing: Blockquote.self))
        }

        aCoder.encode(headerLevel, forKey: EncodingKeys.headerLevel.rawValue)
    }

    override open func setParagraphStyle(_ obj: NSParagraphStyle) {
        super.setParagraphStyle(obj)
        if let paragrahStyle = obj as? ParagraphStyle {
            textList = paragrahStyle.textList
            blockquote = paragrahStyle.blockquote
            headerLevel = paragrahStyle.headerLevel
        }
    }

    open override class var `default`: NSParagraphStyle {
        let style = ParagraphStyle()

        var tabStops = [NSTextTab]()

        for intervalNumber in (1 ..< Metrics.tabStepCount) {
            let location = intervalNumber * Metrics.tabStepInterval
            let textTab = NSTextTab(textAlignment: .natural, location: CGFloat(location), options: [:])

            tabStops.append(textTab)
        }

        style.tabStops = tabStops

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

        if headerLevel != otherParagraph.headerLevel {
            return false
        }
        
        return super.isEqual(object)
    }

    static func ==(lhs: ParagraphStyle, rhs: ParagraphStyle) -> Bool {
        return lhs.isEqual(rhs)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let originalCopy = super.copy(with: zone) as! NSParagraphStyle
        let copy = ParagraphStyle()
        copy.setParagraphStyle(originalCopy)
        copy.textList = textList
        copy.blockquote = blockquote
        copy.headerLevel = headerLevel

        return copy
    }

    open override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let originalCopy = super.mutableCopy(with: zone) as! NSParagraphStyle
        let copy = ParagraphStyle()
        copy.setParagraphStyle(originalCopy)
        copy.textList = textList
        copy.blockquote = blockquote
        copy.headerLevel = headerLevel

        return copy
    }

    open override var hash: Int {
        var hash: Int = super.hash
        if blockquote != nil {
            hash = hash ^ String(describing: Blockquote.self).hashValue
        }
        if let listStyle = textList?.style {
            hash = hash ^ listStyle.hashValue
        }

        hash = hash ^ headerLevel.hashValue
        return hash
    }

    var debugString: String {
        return description
    }

    open override var description:String {
        return super.description + "\nTextList:\(String(describing: textList?.style))\nBlockquote:\(String(describing:blockquote))\nHeaderLevel:\(headerLevel)"
    }
}
