import Foundation
import libxml2

extension Libxml2.In {
    class AttributeConverter: SafeConverter {

        typealias Attribute = Libxml2.Attribute
        typealias StringAttribute = Libxml2.StringAttribute

        /// Converts a single attribute (from libxml2) into an HTML.Attribute
        ///
        /// - Parameters:
        ///     - attributes: the libxml2 attribute to convert.
        ///
        /// - Returns: an HTML.Attribute.
        ///
        func convert(attribute: xmlAttr) -> Attribute {
            guard let attributeName = String(CString: UnsafePointer<Int8>(attribute.name), encoding: NSUTF8StringEncoding) else {
                // We should evaluate how to improve this condition check... is a nil value
                // possible at all here?  If so... do we want to interrupt the parsing or try to
                // recover from it?
                //
                // For the sake of moving forward I'm just interrupting here, but this could change
                // if we find a unit test causing a nil value here.
                //
                fatalError("The attribute name should not be nil.")
            }

            let attributeValueRef = attribute.children

            if attributeValueRef != nil,
                let attributeValue = String(CString: UnsafePointer<Int8>(attributeValueRef.memory.content), encoding: NSUTF8StringEncoding) {

                return StringAttribute(name: attributeName, value: attributeValue)
            } else {
                return Attribute(name: attributeName)
            }
        }
    }
}
