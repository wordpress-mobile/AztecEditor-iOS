import Foundation

open class ParagraphProperty: NSObject, NSCoding {

    var htmlRepresentation: HTMLElementRepresentation?
    
    public override init() {

    }

    public required init?(coder aDecoder: NSCoder) {
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
    }

    static func ==(lhs: ParagraphProperty, rhs: ParagraphProperty) -> Bool {
        return lhs == rhs
    }
}
