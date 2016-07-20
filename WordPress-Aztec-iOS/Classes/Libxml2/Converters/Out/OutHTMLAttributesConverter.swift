import Foundation
import libxml2

extension Libxml2.Out {
    class AttributesConverter: Converter {

        typealias Attribute = HTML.Attribute
        typealias StringAttribute = HTML.StringAttribute

        /// Converts an array of our own representation of attributes into linked list of 
        /// attributes (from libxml2).
        ///
        /// - Parameters:
        ///     - attributes: an array of HTML.Attribute to convert.
        ///
        /// - Returns: the libxml2 attributes. This is a linked list.
        ///
        func convert(attributes: [Attribute]) -> xmlAttr {

            let attributeConverter = AttributeConverter()
            var result: xmlAttr = try attributeConverter.convert(attributes.first!)
            var currentPtr: xmlAttr
            
            for (index, value) in attributes.enumerate() {
                if index > 1 {
                    currentPtr = try attributeConverter.convert(value)
                    result.next = withUnsafeMutablePointer(&currentPtr) {UnsafeMutablePointer<xmlAttr>($0)}
                }
            }
            
            return result
        }
    }
}
