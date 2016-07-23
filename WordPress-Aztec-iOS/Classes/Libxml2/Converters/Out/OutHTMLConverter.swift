import Foundation
import libxml2

extension Libxml2.Out {
    public class HTMLConverter: Converter {
        
        typealias Node = HTML.Node

        /// Converts the a Libxml2 Node into HTML representing the same data.
        ///
        /// - Parameters:
        ///     - rawNode: the Libxml2 Node to convert.
        ///
        /// - Returns: a String object representing the specified HTML data.
        ///
        public func convert(rawNode: Libxml2.HTML.Node) -> String {
            
            let buf = xmlBufferCreate()
            let xmlDocPtr = xmlNewDoc(nil)
            
            // We don't want <p> tags added automattically.
            //
            htmlHandleOmittedElem(0)
            
            let xmlNodePtr = Libxml2.Out.NodeConverter().convert(rawNode)
            
            xmlDocSetRootElement(xmlDocPtr, xmlNodePtr)
            htmlNodeDump(buf, xmlDocPtr, xmlNodePtr)
            
            let htmlDumpString = String(CString: UnsafePointer<Int8>(buf.memory.content), encoding: NSUTF8StringEncoding)!
            
            xmlFreeDoc(xmlDocPtr)
            xmlBufferFree(buf)
            
            return htmlDumpString
        }
    }
}
