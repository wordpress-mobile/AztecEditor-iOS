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


    // MARK: - ElementNode Equatable
    override func isEqual(other: Node) -> Bool {
        guard let commentNode = other as? CommentNode else {
            return false
        }
        return self.name == commentNode.name && self.comment == commentNode.comment
    }

}
