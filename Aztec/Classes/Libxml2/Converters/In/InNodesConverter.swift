import Foundation
import libxml2


/// Converts a C linked list of xmlNode to [HTML.Node].
///
class InNodesConverter: SafeCLinkedListToArrayConverter<InNodeConverter> {
    
    required init() {
        super.init(elementConverter: InNodeConverter(), next: { return $0.next })
    }
}
