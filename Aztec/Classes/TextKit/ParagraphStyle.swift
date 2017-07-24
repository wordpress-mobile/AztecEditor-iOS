import Foundation
import UIKit


// MARK: - ParagraphStyle
//
open class ParagraphStyle: NSMutableParagraphStyle, CustomReflectable {

    // MARK: - CustomReflectable

    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["blockquotes": blockquotes as Any, "headerLevel": headerLevel, "htmlParagraph": htmlParagraph as Any, "textList": lists as Any])
        }
    }

    private enum EncodingKeys: String {
        case headerLevel
    }

    var properties = [ParagraphProperty]()

    var blockquotes: [Blockquote] {
        return properties.flatMap { (property) -> Blockquote? in
            if let blockquote = property as? Blockquote {
                return blockquote
            } else {
                return nil
            }
        }
    }

    var htmlParagraph: [HTMLParagraph] {
        return properties.flatMap { (property) -> HTMLParagraph? in
            if let paragraph = property as? HTMLParagraph {
                return paragraph
            } else {
                return nil
            }
        }
    }

    var lists : [TextList] {
        return properties.flatMap { (property) -> TextList? in
            if let textList = property as? TextList {
                return textList
            } else {
                return nil
            }
        }
    }

    var headers: [Header] {
        return properties.flatMap { (property) -> Header? in
            if let header = property as? Header {
                return header
            } else {
                return nil
            }
        }
    }

    var headerLevel: Int {
        let availableHeaders = headers
        if availableHeaders.isEmpty {
            return 0
        } else {
            return availableHeaders.last!.level.rawValue
        }
    }

    var htmlPre: HTMLPre? {
        let htmlPres = properties.flatMap { (property) -> HTMLPre? in
            if let htmlPre = property as? HTMLPre {
                return htmlPre
            } else {
                return nil
            }
        }
        return htmlPres.first
    }

    override init() {
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {

        if let encodedProperties = aDecoder.decodeObject(forKey:String(describing: ParagraphProperty.self)) as? [ParagraphProperty] {
            properties = encodedProperties
        }

        aDecoder.decodeInteger(forKey: EncodingKeys.headerLevel.rawValue)
        
        super.init(coder: aDecoder)
    }

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)

        aCoder.encode(properties, forKey: String(describing: ParagraphProperty.self))
        aCoder.encode(headerLevel, forKey: EncodingKeys.headerLevel.rawValue)
    }

    override open func setParagraphStyle(_ obj: NSParagraphStyle) {
        super.setParagraphStyle(obj)
        guard let paragrahStyle = obj as? ParagraphStyle else {
            return
        }

        headIndent = 0
        firstLineHeadIndent = 0
        tailIndent = 0
        paragraphSpacing = 0
        paragraphSpacingBefore = 0

        baseHeadIndent = paragrahStyle.baseHeadIndent
        baseFirstLineHeadIndent = paragrahStyle.baseFirstLineHeadIndent
        baseTailIndent = paragrahStyle.baseTailIndent
        baseParagraphSpacing = paragrahStyle.baseParagraphSpacing
        baseParagraphSpacingBefore = paragrahStyle.baseParagraphSpacingBefore

        properties = paragrahStyle.properties
    }

    open override var headIndent: CGFloat {
        get {
            let extra: CGFloat = (CGFloat(lists.count + blockquotes.count) * Metrics.listTextIndentation)

            return baseHeadIndent + extra
        }

        set {
            baseHeadIndent = newValue
        }
    }

    open override var firstLineHeadIndent: CGFloat {
        get {
            let extra: CGFloat = (CGFloat(lists.count + blockquotes.count) * Metrics.listTextIndentation)

            return baseFirstLineHeadIndent + extra
        }

        set {
            baseFirstLineHeadIndent = newValue
        }
    }

    open override var tailIndent: CGFloat {
        get {
            let extra: CGFloat = CGFloat(self.blockquotes.count) * Metrics.defaultIndentation

            return baseTailIndent - extra
        }

        set {
            baseTailIndent = newValue
        }
    }

    private func calculateExtraParagraphSpacing() -> CGFloat {         
        return min(((CGFloat(self.blockquotes.count)) + (self.headerLevel == 0 ? 0.0 : 1.0)), 1.0) * Metrics.paragraphSpacing
    }

    open override var paragraphSpacing: CGFloat {
        get {
            let extra = calculateExtraParagraphSpacing()

            return baseParagraphSpacing + extra
        }

        set {
            baseParagraphSpacing = newValue
        }
    }

    open override var paragraphSpacingBefore: CGFloat {
        get {
            let extra = calculateExtraParagraphSpacing()

            return baseParagraphSpacingBefore + extra
        }

        set {
            baseParagraphSpacingBefore = newValue
        }
    }

    /// The amount of indent for the blockquote of the paragraph if any.
    ///
    public var blockquoteIndent: CGFloat {
        let blockquoteIndex = properties.filter({ property in
            return property is Blockquote || property is TextList
        }).index(where: { property in
            return property is Blockquote
        })

        guard let depth = blockquoteIndex else {
            return 0
        }

        return CGFloat(depth) * Metrics.listTextIndentation
    }

    /// The amount of indent for the list of the paragraph if any.
    ///
    public var listIndent: CGFloat {
        let listAndBlockquotes = properties.filter({ property in
            return property is Blockquote || property is TextList
        })
        var depth = 0
        for position in (0..<listAndBlockquotes.count).reversed() {
            if listAndBlockquotes[position] is TextList {
                depth = position
                break
            }
        }

        return CGFloat(depth) * Metrics.listTextIndentation
    }

    var baseHeadIndent: CGFloat = 0
    var baseFirstLineHeadIndent: CGFloat = 0
    var baseTailIndent: CGFloat = 0
    var baseParagraphSpacing: CGFloat = 0
    var baseParagraphSpacingBefore: CGFloat = 0

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

        if headerLevel != otherParagraph.headerLevel
            || htmlParagraph != otherParagraph.htmlParagraph           
            || properties != otherParagraph.properties {
            return false
        }
        
        return super.isEqual(object)
    }

    static func ==(lhs: ParagraphStyle, rhs: ParagraphStyle) -> Bool {
        return lhs.isEqual(rhs)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = ParagraphStyle()

        copy.setParagraphStyle(self)

        return copy
    }

    open override func mutableCopy(with zone: NSZone? = nil) -> Any {
        let copy = ParagraphStyle()

        copy.setParagraphStyle(self)

        return copy
    }

    open override var hash: Int {
        var hash: Int = super.hash

        for property in properties {
            hash = hash ^ property.hashValue
        }        
        
        return hash
    }

    var debugString: String {
        return description
    }

    open override var description: String {
        return super.description + " Blockquotes: \(String(describing:blockquotes)),\n HeaderLevel: \(headerLevel),\n HTMLParagraph: \(String(describing: htmlParagraph)),\n TextLists: \(lists)"
    }
}


// MARK: - Add method to manipulate properties array
//
extension ParagraphStyle {

    func append(property: ParagraphProperty) {
        properties.append(property)
    }

    func removeProperty(ofType type: AnyClass) {
        for index in (0..<properties.count).reversed() {
            if type(of: properties[index]) == type {
                properties.remove(at: index)
                return
            }
        }
    }

    func replaceProperty(ofType type: AnyClass, with newProperty: ParagraphProperty) {
        for index in (0..<properties.count).reversed() {
            if type(of: properties[index]) == type {
                properties[index] = newProperty
                return
            }
        }
    }
}
