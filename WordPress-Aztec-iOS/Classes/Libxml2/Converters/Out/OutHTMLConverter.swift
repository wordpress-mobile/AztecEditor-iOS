import Foundation
import libxml2

extension Libxml2.Out {
    public class HTMLConverter: Converter {
        
        typealias Node = HTML.Node

        /// Not sure why, but the compiler is requiring this initializer.
        ///
        public init() {
        }

        /// Converts the root node into HTML data representing the same data.
        ///
        /// - Parameters:
        ///     - html: the HTML data to convert.
        ///
        /// - Returns: a NSData object representing the specified HTML data.
        ///
        public func convert(rawNode: Libxml2.HTML.Node) -> String {
            
            let bufferSize = 1024
            let buffer = Array<Int8>(count: bufferSize, repeatedValue: 0)
            let buf = xmlBufferCreate()
            let xmlDocPtr = xmlNewDoc(nil)
            let xmlNodePtr = Libxml2.Out.NodeConverter().convert(rawNode)
            
            xmlDocSetRootElement(xmlDocPtr, xmlNodePtr)
            
            htmlNodeDump(buf, xmlDocPtr, xmlNodePtr)
            
            let htmlDumpString = String(CString: UnsafePointer<Int8>(buf.memory.content), encoding: NSUTF8StringEncoding)!
            
            return htmlDumpString
        }
    }
}
