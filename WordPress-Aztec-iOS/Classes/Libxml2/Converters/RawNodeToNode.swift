import Foundation
import libxml2

extension Libxml2 {
    class RawNodeToNode: Converter {

        typealias TypeIn = xmlNode
        typealias TypeOut = HTML.Node

        /// Converts a single node (from libxml2) into an HTML.Node.
        ///
        /// - Parameters:
        ///     - attributes: the libxml2 attribute to convert.
        ///
        /// - Returns: an HTML.Node.
        ///
        func convert(rawNode: xmlNode) -> HTML.Node {
            guard let nodeName = String(CString: UnsafePointer<Int8>(rawNode.name), encoding: NSUTF8StringEncoding) else {
                // We should evaluate how to improve this condition check... is a nil value
                // possible at all here?  If so... do we want to interrupt the parsing or try to
                // recover from it?
                //
                // For the sake of moving forward I'm just interrupting here, but this could change
                // if we find a unit test causing a nil value here.
                //
                fatalError("The node name should not be nil.")
            }

            let node = HTML.Node(name: nodeName)

            let converter = RawAttributesToAttributes()
            let attributes2 = converter.convert(rawNode.properties)
            node.append(attributes: attributes2)

            return node
        }
    }
}