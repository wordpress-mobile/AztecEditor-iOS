import Foundation
import libxml2

class InAttributeConverter: SafeConverter {

    /// Converts a single attribute (from libxml2) into an HTML.Attribute
    ///
    /// - Parameters:
    ///     - attributes: the libxml2 attribute to convert.
    ///
    /// - Returns: an HTML.Attribute.
    ///
    func convert(_ attribute: xmlAttr) -> Attribute {
        
        let attributeName = String(cString: attribute.name)
        let attributeValueRef = attribute.children

        if let attributeValueRef = attributeValueRef {
            let string = String(cString: attributeValueRef.pointee.content)
            
            return Attribute(name: attributeName, value: .string(string))
        } else {
            return Attribute(name: attributeName)
        }
    }
}
