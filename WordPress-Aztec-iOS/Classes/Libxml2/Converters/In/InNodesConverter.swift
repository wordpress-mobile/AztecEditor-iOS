import Foundation
import libxml2

extension Libxml2.In {
    class NodesConverter: Converter {

        typealias Node = HTML.Node
        typealias StringAttribute = HTML.StringAttribute

        /// Converts a linked list of xmlNode (from libxml2) into [HTML.Node].
        ///
        /// - Parameters:
        ///     - attributes: the libxml2 nodes to convert.  This is a linked list.
        ///
        /// - Returns: an array of HTML.Node.
        ///
        func convert(nodes: xmlNodePtr) -> [Node] {

            let listToArrayConverter = CLinkedListToArrayConverter(elementConverter: NodeConverter()) {
                return $0.next
            }

            return listToArrayConverter.convert(nodes)
        }
    }
}