import Foundation

protocol EditableNode {
    func deleteCharacters(inRange range: NSRange)
    func replaceCharacters(inRange range: NSRange, withString string: String)
    
    /// Should split the node at the specified text location.  The receiver will become the node before the specified
    /// location and a new node will be created to contain whatever comes after it.
    ///
    /// - Parameters:
    ///     - location: the text location to split the node at.
    ///
    func split(atLocation location: Int)
    func split(forRange range: NSRange)
    func wrap(range targetRange: NSRange, inNodeNamed nodeName: String, withAttributes attributes: [Libxml2.Attribute])
}
