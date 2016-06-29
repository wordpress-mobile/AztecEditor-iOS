import Foundation
import libxml2

extension Libxml2 {
    class RawAttributesToAttributes: Converter {

        typealias Attribute = HTML.Attribute
        typealias StringAttribute = HTML.StringAttribute

        typealias TypeIn = xmlAttrPtr
        typealias TypeOut = [Attribute]

        func convert(attributes: xmlAttrPtr) -> [Attribute] {

            var result = [Attribute]()
            var currentAttributePtr = attributes

            while (currentAttributePtr != nil) {
                let attribute = currentAttributePtr.memory

                let attributeConverter = RawAttributeToAttribute()
                result.append(attributeConverter.convert(attribute))
                
                currentAttributePtr = attribute.next
            }
            
            return result
        }
    }
}
