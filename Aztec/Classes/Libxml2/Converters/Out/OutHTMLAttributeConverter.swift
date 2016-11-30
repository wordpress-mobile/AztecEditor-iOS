import Foundation
import libxml2

extension Libxml2.Out {
    class AttributeConverter: Converter {

        typealias Attribute = Libxml2.Attribute
        typealias StringAttribute = Libxml2.StringAttribute

        fileprivate let node: xmlNodePtr

        init(forNode node: xmlNodePtr? = nil) {
            self.node = node!
        }
        
        /// Converts a single HTML.Attribute into a single libxml2 attribute
        ///
        /// - Parameters:
        ///     - attribute: the HTML.Attribute to convert.
        ///
        /// - Returns: an libxml2 attribute.
        ///
        func convert(_ rawAttribute: Attribute) -> xmlAttrPtr {
            var attribute: xmlAttrPtr
            
            if let stringAttribute = rawAttribute as? StringAttribute {
                attribute = createStringAttribute(stringAttribute)
            } else {
                attribute = createAttribute(rawAttribute)
            }
            
            return attribute;
        }
        
        /// Creates a libxml2 string attribute from a HTML.StringAttribute.
        ///
        /// - Parameters:
        ///     - rawAttribute: HTML.StringAttribute.
        ///
        /// - Returns: libxml2 string attribute
        ///
        fileprivate func createStringAttribute(_ rawStringAttribute: StringAttribute) -> xmlAttrPtr {
            let name = rawStringAttribute.name
            let nameCStr = name.cString(using: String.Encoding.utf8)!
            let namePtr = UnsafePointer<xmlChar>(OpaquePointer(nameCStr))
            
            let value = rawStringAttribute.value
            let valueCStr = value.cString(using: String.Encoding.utf8)!
            let valuePtr = UnsafePointer<xmlChar>(OpaquePointer(valueCStr))
            
            return xmlNewProp(node, namePtr, valuePtr)
        }
        
        /// Creates a libxml2 attribute from a HTML.Attribute.
        ///
        /// - Parameters:
        ///     - rawAttribute: HTML.Attribute.
        ///
        /// - Returns: libxml2 attribute
        ///
        fileprivate func createAttribute(_ rawAttribute: Attribute) -> xmlAttrPtr {
            let name = rawAttribute.name
            let nameCStr = name.cString(using: String.Encoding.utf8)!
            let namePtr = UnsafePointer<xmlChar>(OpaquePointer(nameCStr))
            
            return xmlNewProp(node, namePtr, nil)
        }
    }
}
