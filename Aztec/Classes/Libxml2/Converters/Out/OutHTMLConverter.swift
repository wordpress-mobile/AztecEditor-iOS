import Foundation
import libxml2

extension Libxml2.Out {
    class HTMLConverter: Converter {
        
        typealias Node = Libxml2.Node
        typealias ElementNode = Libxml2.ElementNode
        typealias RootNode = Libxml2.RootNode
        
        required init() {
        }

        /// Converts the a Libxml2 Node into HTML representing the same data.
        ///
        /// - Parameters:
        ///     - rawNode: the Libxml2 Node to convert.
        ///
        /// - Returns: a String object representing the specified HTML data.
        ///
        func convert(_ rawNode: Node) -> String {

            guard let outputBuffer = xmlAllocOutputBuffer(nil) else {
                fatalError("This should not ever happen. Prevent the code from going further to avoid possible data loss.")
            }

            let xmlDocPtr = xmlNewDoc(nil)

            defer {
                xmlFreeDoc(xmlDocPtr)
                xmlOutputBufferClose(outputBuffer)
            }

            let xmlNodePtr = Libxml2.Out.NodeConverter().convert(rawNode)

            xmlDocSetRootElement(xmlDocPtr, xmlNodePtr)
            htmlNodeDumpFormatOutput(outputBuffer, xmlDocPtr, xmlNodePtr, "UTF-8", 0)

            let buffer = xmlBufContent(outputBuffer.pointee.buffer)!

            let finalBuffer = buffer.withMemoryRebound(to: CChar.self, capacity: 10) { ptr -> UnsafePointer<CChar> in
                return UnsafePointer<CChar>(ptr)
            }

            let htmlDumpString = String(utf8String: finalBuffer)!

            //let htmlDumpString = String(cString: xmlBufContent(outputBuffer.pointee.buffer))

            let finalString = htmlDumpString.replacingOccurrences(of: "<\(RootNode.name)>", with: "").replacingOccurrences(of: "</\(RootNode.name)>", with: "")

            return finalString
        }
    }
}
