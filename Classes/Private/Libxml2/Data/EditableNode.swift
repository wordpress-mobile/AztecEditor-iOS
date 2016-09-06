import Foundation

protocol EditableNode {
    func deleteCharacters(inRange range: NSRange);
    func replaceCharacters(inRange range: NSRange, withString string: String);
    func split(forRange range: NSRange);
    func wrap(range targetRange: NSRange, inNodeNamed nodeName: String, withAttributes attributes: [Libxml2.Attribute]);
}
