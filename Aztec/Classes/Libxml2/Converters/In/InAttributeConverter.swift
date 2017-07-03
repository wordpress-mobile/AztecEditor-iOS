import Foundation
import libxml2

extension Libxml2.In {
    class AttributeConverter: SafeConverter {

        typealias Attribute = Libxml2.Attribute

        /// Used to identify any attribute that contains inline CSS styling info.
        ///
        let cssStyleAttribute = "style"

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
                
                return StringAttribute(name: attributeName, value: attributeValue)
            } else {
                return Attribute(name: attributeName)
            }
        }
    }
}
