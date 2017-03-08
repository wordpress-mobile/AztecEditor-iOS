import Foundation

extension Libxml2 {

    /// Editing Marker nodes contain meta data used by the DOM editing logic.
    ///
    class EditingMarkerNode : Node {

        static let nodeName = "editingMarkerNode"

        enum MarkerType {
            case listItemSeparator
        }

        let markerType: MarkerType

        init(withType markerType: MarkerType) {
            self.markerType = markerType

            super.init(name: EditingMarkerNode.nodeName)
        }
    }
}
