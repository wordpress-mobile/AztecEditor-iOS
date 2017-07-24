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
            let attributeValue = String(cString: attributeValueRef.pointee.content)

            // The HTML 5 spec, in Section 2.4.2 (named "Boolean attributes") provides some examples
            // showing that attributes that have a value equal to their names are boolean attributes
            // and can be equivalently written without their value.  The latter is the normalized
            // representation we currently support.
            //
            // So we're only loading the attribute's value if it's not equal to the attribute name.
            //
            if attributeName != attributeValue {
                return Attribute(name: attributeName, string: attributeValue)
            }
        }

        return Attribute(name: attributeName)
    }
}
