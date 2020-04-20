import Foundation
import libxml2


/// Converts a C linked list of xmlNode to [HTML.Node].
///
class InNodesConverter: SafeCLinkedListToArrayConverter<InNodeConverter> {

    let shouldCollapseSpaces: Bool

    required init(shouldCollapseSpaces: Bool = true) {
        self.shouldCollapseSpaces = shouldCollapseSpaces
        super.init(elementConverter: InNodeConverter(shouldCollapseSpaces: shouldCollapseSpaces), next: { return $0.next })
    }
}
