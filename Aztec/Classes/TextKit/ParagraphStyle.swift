import Foundation
import UIKit

// MARK: - ParagraphStyle
//
open class ParagraphStyle: NSMutableParagraphStyle, CustomReflectable {

    // MARK: - CustomReflectable
    
    public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["blockquotes": blockquotes,
                                           "headerLevel": headerLevel,
                                           "htmlDiv": htmlDiv,
                                           "htmlParagraph": htmlParagraph,
                                           "textList": lists,
                                           "properties": properties])
        }
    }

    private enum EncodingKeys: String {
        case headerLevel
    }

    var properties = [ParagraphProperty]()

    var blockquotes: [Blockquote] {
        return properties.flatMap { property in
            return property as? Blockquote
        }
    }

    var htmlDiv: [HTMLDiv] {
        return properties.flatMap { property in
            return property as? HTMLDiv
        }
    }

    var htmlParagraph: [HTMLParagraph] {
        return properties.flatMap { property in
            return property as? HTMLParagraph
        }
    }

    var lists : [TextList] {
        return properties.flatMap { property in
            return property as? TextList
        }
    }

    var headers: [Header] {
        return properties.flatMap { property in
            return property as? Header
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
        let htmlPres = properties.flatMap { property in
            return property as? HTMLPre
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

    override open func setParagraphStyle(_ baseParagraphStyle: NSParagraphStyle) {
        
        super.setParagraphStyle(baseParagraphStyle)
        
        guard let paragraphStyle = baseParagraphStyle as? ParagraphStyle else {
            return
        }
    
        // IMPORTANT: It's important to keep the implementation of this method custom for our ParagraphStyle class.
        // The parent call tries to copy the properties that this class turned into calculated properties.
        
        // IMPORTANT 2: It's important to copy lists, blockquotes, etc before the other properties, since their values are
        // calculated and sometimes based in these.
        properties = paragraphStyle.properties
        
        baseHeadIndent = paragraphStyle.baseHeadIndent
        baseFirstLineHeadIndent = paragraphStyle.baseFirstLineHeadIndent
        baseTailIndent = paragraphStyle.baseTailIndent
        
        blockquoteParagraphSpacing = paragraphStyle.blockquoteParagraphSpacing
        blockquoteParagraphSpacingBefore = paragraphStyle.blockquoteParagraphSpacingBefore
        
        regularParagraphSpacing = paragraphStyle.regularParagraphSpacing
        regularParagraphSpacingBefore = paragraphStyle.regularParagraphSpacingBefore
        
        textListParagraphSpacing = paragraphStyle.textListParagraphSpacing
        textListParagraphSpacingBefore = paragraphStyle.textListParagraphSpacingBefore
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
            // We're basically ignoring this by setting it on the parent.
            super.firstLineHeadIndent = newValue
        }
    }

    open override var tailIndent: CGFloat {
        get {
            let extra: CGFloat = CGFloat(self.blockquotes.count) * Metrics.defaultIndentation

            return baseTailIndent - extra
        }

        set {
            // We're basically ignoring this by setting it on the parent.
            super.tailIndent = newValue
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

    open var baseHeadIndent: CGFloat = 0
    open var baseFirstLineHeadIndent: CGFloat = 0
    open var baseTailIndent: CGFloat = 0
    
    open var regularParagraphSpacing = CGFloat(0)
    open var regularParagraphSpacingBefore = CGFloat(0)
    
    open var textListParagraphSpacing = CGFloat(0)
    open var textListParagraphSpacingBefore = CGFloat(0)
    
    open var blockquoteParagraphSpacing = CGFloat(0)
    open var blockquoteParagraphSpacingBefore = CGFloat(0)
    
    open override var paragraphSpacing: CGFloat {
        get {
            if blockquotes.count > 0 {
                return blockquoteParagraphSpacing
            } else if lists.count > 0 {
                return textListParagraphSpacing
            } else {
                return regularParagraphSpacing
            }
        }
        
        set {
            super.paragraphSpacing = newValue
        }
    }
    
    open override var paragraphSpacingBefore: CGFloat {
        get {
            if blockquotes.count > 0 {
                return blockquoteParagraphSpacingBefore
            } else if lists.count > 0 {
                return textListParagraphSpacingBefore
            } else {
                return regularParagraphSpacingBefore
            }
        }
        
        set {
            super.paragraphSpacingBefore = newValue
        }
    }
    
    // MARK: - Defaults
    
    open override class var `default`: ParagraphStyle {
        let style = ParagraphStyle()
        
        var tabStops = [NSTextTab]()
        
        for intervalNumber in (1 ..< Metrics.tabStepCount) {
            let location = intervalNumber * Metrics.tabStepInterval
            let textTab = NSTextTab(textAlignment: .natural, location: CGFloat(location), options: [:])
            
            tabStops.append(textTab)
        }
        
        style.tabStops = tabStops
        style.lineSpacing = 8
        style.blockquoteParagraphSpacing = 8
        style.blockquoteParagraphSpacingBefore = 8
        style.regularParagraphSpacing = 8
        style.regularParagraphSpacingBefore = 8
        style.textListParagraphSpacing = 0
        style.textListParagraphSpacingBefore = 0
        
        return style
    }

    // MARK: - Equatable
    
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
        return super.description +
            " Blockquotes: \(String(describing:blockquotes)),\n" +
            " HeaderLevel: \(headerLevel),\n" +
            " HTMLDiv: \(String(describing: htmlDiv)),\n" +
            " HTMLParagraph: \(String(describing: htmlParagraph)),\n" +
            " TextLists: \(lists)"
    }
}


// MARK: - Add method to manipulate properties array
//
extension ParagraphStyle {

    /// Inserts the specified ParagraphProperty at the very end of the Properties array
    ///
    func appendProperty(_ property: ParagraphProperty) {
        properties.append(property)
    }

    /// Inserts the specified ParagraphProperty at the specified index
    ///
    func insertProperty(_ property: ParagraphProperty, at index: Int) {
        properties.insert(property, at: index)
    }

    /// Inserts the specified ParagraphProperty after the last Property of the specified kind. If none,
    /// this method will simply append the given ParagraphProperty at the very end of the Properties array.
    ///
    /// *Note*: This is specially useful when adding a nested List Nested Level, where 'New Lists' should be
    /// clustered at the 'Right Hand Side' of the currently existant list.
    ///
    func insertProperty(_ property: ParagraphProperty, afterLastOfType type: AnyClass) {
        guard let targetIndex = properties.lastIndex(where: { Swift.type(of: $0) == type }) else {
            properties.append(property)
            return
        }

        properties.insert(property, at: targetIndex + 1)
    }

    /// Removes the first ParagraphProperty present in the Properties collection that matches the specified kind.
    ///
    func removeProperty(ofType type: AnyClass) {
        for index in (0..<properties.count).reversed() {
            if Swift.type(of: properties[index]) == type {
                properties.remove(at: index)
                return
            }
        }
    }

    /// Replaces the first ParagraphProperty present in the Properties collection with a given instance
    ///
    func replaceProperty(ofType type: AnyClass, with newProperty: ParagraphProperty) {
        for index in (0..<properties.count).reversed() {
            if Swift.type(of: properties[index]) == type {
                properties[index] = newProperty
                return
            }
        }
    }
}
