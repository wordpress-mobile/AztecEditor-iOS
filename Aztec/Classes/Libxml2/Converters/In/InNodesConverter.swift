import Foundation
import libxml2

extension Libxml2.In {

    /// Converts a C linked list of xmlNode to [HTML.Node].
    ///
    class NodesConverter: SafeCLinkedListToArrayConverter<NodeConverter> {
        
        typealias EditContext = Libxml2.EditContext
        
        required init(editContext: EditContext? = nil) {
            super.init(elementConverter: NodeConverter(editContext: editContext), next: { return $0.next })
        }
    }
}
