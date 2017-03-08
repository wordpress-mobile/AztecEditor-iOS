import Foundation

extension Libxml2 {
    /// The Edit Context class is useful for specifying whatever editing state and logic needs to
    /// be shared across the full DOM tree.
    ///
    class EditContext {

        // MARK: - Properties: Undo support
        
        let undoManager: UndoManager

        // MARK: - Initializers
        
        init(undoManager: UndoManager) {
            self.undoManager = undoManager
        }
    }
}
