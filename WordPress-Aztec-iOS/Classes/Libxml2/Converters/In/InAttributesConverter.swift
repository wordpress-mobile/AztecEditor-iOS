import Foundation
import libxml2

extension Libxml2.In {

    /// Converts a C linked list of xmlAttr to [HTML.Attribute].
    ///
    class AttributesConverter: CLinkedListToArrayConverter<AttributeConverter> {

        required init() {
            super.init(elementConverter: AttributeConverter(), next: { return $0.next })
        }
    }
}
