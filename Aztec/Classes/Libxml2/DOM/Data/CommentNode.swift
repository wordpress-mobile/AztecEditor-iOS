import Foundation


/// Comment nodes use to hold HTML comments like this: <!-- This is a comment -->
///
class CommentNode: Node {

    var comment: String

    // MARK: - CustomReflectable
    
    override public var customMirror: Mirror {
        get {
            return Mirror(self, children: ["type": "comment", "name": name, "comment": comment, "parent": parent.debugDescription], ancestorRepresentation: .suppressed)
        }
    }
    
    // MARK: - Initializers
    
    init(text: String) {
        comment = text

        super.init(name: "comment")
    }

    // MARK - Hashable

    override public var hashValue: Int {
        return name.hashValue ^ comment.hashValue
    }

    // MARK: - Equatable

    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? CommentNode else {
            return false
        }

        return name == rhs.name && comment == rhs.comment
    }
}
