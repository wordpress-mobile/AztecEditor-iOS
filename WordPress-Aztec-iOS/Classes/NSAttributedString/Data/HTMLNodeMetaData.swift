import Foundation

/// Class for storing meta-data for a single HTML node.
///
class HTMLNodeMetaData: CustomReflectable {

    /// The tag name.  The node name.  For example in the case of `<strong>` the name would be
    /// "strong".
    ///
    var name: String

    /// The HTML attributes for this node.
    ///
    var attributes = [HTMLAttributeMetaData]()

    /// Unique ID to identify the tag.  Unfortunately we can't just use the tag name because
    /// doing so would break in cases such as `<div><div>...content...</div></div>`.
    ///
    let uuid = NSUUID().UUIDString

    // MARK: - Tag hierarchy

    /// Child tag.
    ///
    weak var child: HTMLNodeMetaData?

    /// Parent tag.
    ///
    weak var parent: HTMLNodeMetaData?

    // MARK: - Init

    init(name: String, attributes: [HTMLAttributeMetaData]) {
        self.name = name
        self.attributes.appendContentsOf(attributes)
    }

    // MARK: - Attribute Key

    static func key(forTagNamed name: String, uniqueId uuid: String) -> String {
        return "Aztec.HTMLTag.\(name).\(uuid)"
    }

    func key() -> String {
        return self.dynamicType.key(forTagNamed: name, uniqueId: uuid)
    }

    // MARK: - CustomReflectable

    public func customMirror() -> Mirror {
        return Mirror(self, children: ["name": name, "parent": parent, "child": child])
    }
}
