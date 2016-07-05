import Foundation
import libxml2

extension Libxml2.In {

    class AttributesConverter: Converter {

        func convert(attributes: xmlAttrPtr) -> [HTML.Attribute] {

            let listToArrayConverter = CLinkedListToArrayConverter(elementConverter: AttributeConverter()) {
                return $0.next
            }

            return listToArrayConverter.convert(attributes)
        }
    }
}
