import Foundation

protocol EditableNode {
    func deleteCharacters(inRange range: NSRange, undoManager: NSUndoManager?)
    
    /// Replaces the specified range with a new string.
    ///
    /// - Parameters:
    ///     - range: the range of the original string to replace.
    ///     - string: the new string to replace the original text with.
    ///     - inheritStyle: If `true` the new string will inherit the style information from the first position in
    ///             the specified range.  If `false`, the new sting will have no associated style.
    ///
    func replaceCharacters(inRange range: NSRange, withString string: String, inheritStyle: Bool, undoManager: NSUndoManager?)

    /// Should split the node at the specified text location.  The receiver will become the node before the specified
    /// location and a new node will be created to contain whatever comes after it.
    ///
    /// - Parameters:
    ///     - location: the text location to split the node at.
    ///
    func split(atLocation location: Int, undoManager: NSUndoManager?)
    func split(forRange range: NSRange, undoManager: NSUndoManager?)
    func wrap(range targetRange: NSRange, inElement elementDescriptor: Libxml2.ElementNodeDescriptor, undoManager: NSUndoManager?)
}
