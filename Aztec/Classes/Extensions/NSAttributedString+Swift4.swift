import Foundation

#if swift(>=4.0)
#else
    public extension NSAttributedString {
        public convenience init(string: String, attributes: [AttributedStringKey: Any]) {
            let convertedAttributes = AttributedStringKey.convertToRaw(attributes)
            
            self.init(string: string, attributes: convertedAttributes)
        }
    }
#endif
