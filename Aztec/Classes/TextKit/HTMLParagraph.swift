import Foundation

class HTMLParagraph: NSObject, NSCoding {
    public func encode(with aCoder: NSCoder) {

    }

    override public init() {

    }

    required public init?(coder aDecoder: NSCoder){

    }

    static func ==(lhs: HTMLParagraph, rhs: HTMLParagraph) -> Bool {
        return lhs === rhs
    }
}
