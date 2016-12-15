import Foundation

protocol EditableNode {
    func deleteCharacters(inRange range: NSRange, undoManager: UndoManager?)
    
    /// Replaces the specified range with a new string.
    ///
    /// - Parameters:
    ///     - range: the range of the original string to replace.
    ///     - string: the new string to replace the original text with.
    ///     - inheritStyle: If `true` the new string will inherit the style information from the first position in
    ///             the specified range.  If `false`, the new sting will have no associated style.
    ///     - undoManager: the undo manager for the operation.
    ///
    func replaceCharacters(inRange range: NSRange, withString string: String, inheritStyle: Bool, undoManager: UndoManager?)

    /// Should split the node at the specified text location.  The receiver will become the node before the specified
    /// location and a new node will be created to contain whatever comes after it.
    ///
    /// - Parameters:
    ///     - location: the text location to split the node at.
    ///     - undoManager: the undo manager for the operation.
    ///
    func split(atLocation location: Int, undoManager: UndoManager?)
    
    /// Should split the node for the specified text range.  The receiver will become the node
    /// at the specified range.
    ///
    /// - Parameters:
    ///     - range: the range to use for splitting the node.
    ///     - undoManager: the undo manager for the operation.
    ///
    func split(forRange range: NSRange, undoManager: UndoManager?)
    
    /// Wraps the specified range in the specified element.
    ///
    /// - Parameters:
    ///     - range: the range to wrap.
    ///     - elementDescriptor: the element to wrap the range in.
    ///     - undoManager: the undo manager for the operation.
    ///
    ///
    func wrap(range targetRange: NSRange, inElement elementDescriptor: Libxml2.ElementNodeDescriptor, undoManager: UndoManager?)
}
