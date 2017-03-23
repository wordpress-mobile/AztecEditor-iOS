import Foundation

extension Libxml2 {
    /// The Edit Context class is useful for specifying whatever editing state and logic needs to
    /// be shared across the full DOM tree.
    ///
    struct EditContext {

        // MARK: - Properties: Undo support
        
        let undoManager: UndoManager

        /// If this property is true the text nodes will be cleared of any extra space or newlines characteres they may have on them.
        var sanitizeText: Bool = true

        // MARK: - Initializers
        
        init(undoManager: UndoManager) {
            self.undoManager = undoManager
        }
    }
}
