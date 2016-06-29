import Foundation
import libxml2

class RawAttributesToAttributes: Converter {

    typealias Attribute = HTML.Attribute
    typealias Attributes = [Attribute]
    typealias StringAttribute = HTML.StringAttribute

    typealias TypeIn = xmlAttrPtr
    typealias TypeOut = Attributes

    func convert(attributes: xmlAttrPtr) -> [HTML.Attribute] {

        var result = Attributes()
        var currentAttributePtr = attributes

        while (currentAttributePtr != nil) {

            let attribute = currentAttributePtr.memory

            guard let attributeName = String(CString: UnsafePointer<Int8>(attribute.name), encoding: NSUTF8StringEncoding) else {
                // We should evaluate how to improve this condition check... is a nil value
                // possible at all here?  If so... do we want to interrupt the parsing or try to
                // recover from it?
                //
                // For the sake of moving forward I'm just interrupting here, but this could change
                // if we find a unit test causing a nil value here.
                //
                fatalError("The root element name should not be nil.")
            }

            let attributeValueRef = attribute.children

            if attributeValueRef != nil,
                let attributeValue = String(CString: UnsafePointer<Int8>(attributeValueRef.memory.content), encoding: NSUTF8StringEncoding) {

                let attribute = StringAttribute(name: attributeName, value: attributeValue)
                result.append(attribute)
            } else {
                let attribute = Attribute(name: attributeName)
                result.append(attribute)
            }
            
            currentAttributePtr = attribute.next
        }
        
        return result
    }
}