import Foundation

extension UndoManager {
    
    /// Closes all open undo groups in an undo manager.
    ///
    func closeAllUndoGroups() {
        while (groupingLevel > 0) {
            endUndoGrouping()
        }
    }
}
