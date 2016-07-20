import Foundation
import libxml2

extension Libxml2.Out {
    class NodesConverter: Converter {

        typealias Node = HTML.Node
        typealias StringAttribute = HTML.StringAttribute

        /// Converts a array of HTML.Node into a linked list of xmlNode (from libxml2).
        ///
        /// - Parameters:
        ///     - attributes: the array of HTML.Node to convert.
        ///
        /// - Returns: an a linked list of xmlNode (from libxml2).
        ///
        func convert(nodes: [Node]) -> xmlNode {
           
            let attributeConverter = NodeConverter()
            var result: xmlNode = try attributeConverter.convert(nodes.first!)
            var currentPtr: xmlNode
            
            for (index, value) in nodes.enumerate() {
                if index > 1 {
                    currentPtr = try attributeConverter.convert(value)
                    result.next = withUnsafeMutablePointer(&currentPtr) {UnsafeMutablePointer<xmlNode>($0)}
                }
            }
            
            return result
        }
    }
}