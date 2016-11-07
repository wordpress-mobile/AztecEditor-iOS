import Foundation
import libxml2

extension Libxml2.Out {
    class AttributeConverter: Converter {

        typealias Attribute = Libxml2.Attribute
        typealias StringAttribute = Libxml2.StringAttribute

        private let node: xmlNodePtr

        init(forNode node: xmlNodePtr = nil) {
            self.node = node
        }
        
        /// Converts a single HTML.Attribute into a single libxml2 attribute
        ///
        /// - Parameters:
        ///     - attribute: the HTML.Attribute to convert.
        ///
        /// - Returns: an libxml2 attribute.
        ///
        func convert(rawAttribute: Attribute) -> UnsafeMutablePointer<xmlAttr> {
            var attribute: UnsafeMutablePointer<xmlAttr>!
            
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
        private func createStringAttribute(rawStringAttribute: StringAttribute) -> UnsafeMutablePointer<xmlAttr> {
            let name = rawStringAttribute.name
            let nameCStr = name.cStringUsingEncoding(NSUTF8StringEncoding)!
            let namePtr = UnsafePointer<xmlChar>(nameCStr)
            
            let value = rawStringAttribute.value
            let valueCStr = value.cStringUsingEncoding(NSUTF8StringEncoding)!
            let valuePtr = UnsafeMutablePointer<xmlChar>(valueCStr)

            return xmlNewProp(node, namePtr, valuePtr)
        }
        
        /// Creates a libxml2 attribute from a HTML.Attribute.
        ///
        /// - Parameters:
        ///     - rawAttribute: HTML.Attribute.
        ///
        /// - Returns: libxml2 attribute
        ///
        private func createAttribute(rawAttribute: Attribute) -> UnsafeMutablePointer<xmlAttr> {
            let name = rawAttribute.name
            let nameCStr = name.cStringUsingEncoding(NSUTF8StringEncoding)!
            let namePtr = UnsafePointer<xmlChar>(nameCStr)
            
            return xmlNewProp(node, namePtr, nil)
        }
    }
}
