import Foundation
import libxml2

extension Libxml2.In {

    /// Converts a C linked list of xmlNode to [HTML.Node].
    ///
    class NodesConverter: CLinkedListToArrayConverter<NodeConverter> {

        required init() {
            super.init(elementConverter: NodeConverter(), next: { return $0.next })
        }
    }
}