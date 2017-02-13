import Foundation

class Blockquote: NSObject, NSCoding {
    public func encode(with aCoder: NSCoder) {

    }

    override public init() {

    }

    required public init?(coder aDecoder: NSCoder){

    }

    static func ==(lhs: Blockquote, rhs: Blockquote) -> Bool {
        return true
    }
}

