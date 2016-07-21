import Foundation
import libxml2

extension Libxml2.Out {
    class AttributeConverter: Converter {

        typealias Attribute = HTML.Attribute
        typealias StringAttribute = HTML.StringAttribute
        
        /// Converts a single HTML.Attribute into a single libxml2 attribute
        ///
        /// - Parameters:
        ///     - attribute: the HTML.Attribute to convert.
        ///
        /// - Returns: an libxml2 attribute.
        ///
        func convert(rawAttribute: Attribute) -> xmlAttr {
            var attribute: xmlAttr!
            
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
        private func createStringAttribute(rawStringAttribute: StringAttribute) -> xmlAttr {
            let name = rawStringAttribute.name
            let nameCStr = name.cStringUsingEncoding(NSUTF8StringEncoding)!
            let namePtr = UnsafePointer<xmlChar>(nameCStr)
            
            let value = rawStringAttribute.value
            let valueCStr = value.cStringUsingEncoding(NSUTF8StringEncoding)!
            let valuePtr = UnsafeMutablePointer<xmlChar>(valueCStr)
            
            var node = xmlNode()
            node.content = valuePtr
            
            var xmlAttribute = xmlAttr()
            xmlAttribute.name = namePtr
            xmlAttribute.children = withUnsafeMutablePointer(&node) {UnsafeMutablePointer<xmlNode>($0)}
            
            return xmlAttribute
        }
        
        /// Creates a libxml2 attribute from a HTML.Attribute.
        ///
        /// - Parameters:
        ///     - rawAttribute: HTML.Attribute.
        ///
        /// - Returns: libxml2 attribute
        ///
        private func createAttribute(rawAttribute: Attribute) -> xmlAttr {
            let name = rawAttribute.name
            let nameCStr = name.cStringUsingEncoding(NSUTF8StringEncoding)!
            let namePtr = UnsafePointer<xmlChar>(nameCStr)
            
            var xmlAttribute = xmlAttr()
            xmlAttribute.name = namePtr
            
            return xmlAttribute
        }
    }
}
