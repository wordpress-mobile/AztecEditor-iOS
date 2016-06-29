extension HTML {

    public class Node: CustomDebugStringConvertible {
        let name: String
        private(set) var attributes = [Attribute]()

        public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType)): {name: \(name); attributes: \(String(attributes))}>"
            }
        }

        init(name: String) {
            self.name = name
        }

        func append(attributes attributes: [Attribute]) {
            self.attributes.appendContentsOf(attributes)
        }
    }
}