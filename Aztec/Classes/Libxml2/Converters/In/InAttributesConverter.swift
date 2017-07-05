import Foundation
import libxml2


/// Converts a C linked list of xmlAttr to [HTML.Attribute].
///
class InAttributesConverter: SafeCLinkedListToArrayConverter<InAttributeConverter> {

    required init() {
        super.init(elementConverter: InAttributeConverter(), next: { return $0.next })
    }
}
