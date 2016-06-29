import Foundation
import libxml2

extension Libxml2 {
    class HTMLNodesConverter: Converter {

        typealias Node = HTML.Node
        typealias StringAttribute = HTML.StringAttribute

        typealias TypeIn = xmlNodePtr
        typealias TypeOut = [Node]

        /// Converts a linked list of xmlNode (from libxml2) into [HTML.Node].
        ///
        /// - Parameters:
        ///     - attributes: the libxml2 nodes to convert.  This is a linked list.
        ///
        /// - Returns: an array of HTML.Node.
        ///
        func convert(nodes: xmlNodePtr) -> [Node] {

            var result = [Node]()
            var currentNodePtr = nodes

            while (currentNodePtr != nil) {
                let node = currentNodePtr.memory

                let nodeConverter = HTMLNodeConverter()
                result.append(nodeConverter.convert(node))

                currentNodePtr = node.next
            }
            
            return result
        }
    }
}