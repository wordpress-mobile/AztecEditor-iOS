import Foundation
import libxml2

class InAttributeConverter: SafeConverter {

    let cssParser = CSSParser()

    /// Converts a single attribute (from libxml2) into an HTML.Attribute
    ///
    /// - Parameters:
    ///     - attributes: the libxml2 attribute to convert.
    ///
    /// - Returns: an HTML.Attribute.
    ///
    func convert(_ attribute: xmlAttr) -> Attribute {

        let attributeName = String(cString: attribute.name)
        let attributeType = AttributeType(attributeName)

        guard let attributeValueRef = attribute.children else {
            return Attribute(type: attributeType)
        }

        let attributeValue = String(cString: attributeValueRef.pointee.content)

        // The HTML 5 spec, in Section 2.4.2 (named "Boolean attributes") provides some examples
        // showing that attributes that have a value equal to their names are boolean attributes
        // and can be equivalently written without their value.  The latter is the normalized
        // representation we currently support.
        //
        // So we're only loading the attribute's value if it's not equal to the attribute name.
        //
        guard attributeName != attributeValue else {
            return Attribute(type: attributeType)
        }
        
        if AttributeType.cssAttributeTypes.contains(attributeType) {
            let cssAttributes = cssParser.parse(attributeValue)
            
            return Attribute(type: attributeType, value: .inlineCss(cssAttributes))
        }
        
        return Attribute(type: attributeType, value: .string(attributeValue))
    }
}
