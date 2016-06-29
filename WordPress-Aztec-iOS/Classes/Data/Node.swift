extension HTML {

    public class Node: CustomDebugStringConvertible {

        private(set) var attributes = [Attribute]()
        let name: String
        let child: Node?

        public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType)): {name: \(name); attributes: \(String(attributes)); child: \(String(child))}>"
            }
        }

        init(name: String, child: Node?) {
            self.name = name
            self.child = child
        }

        func append(attributes attributes: [Attribute]) {
            self.attributes.appendContentsOf(attributes)
        }
    }

    public class TextNode: Node {

        let text: String

        override public var debugDescription: String {
            get {
                return "<\(String(self.dynamicType)): {name: \(name); text: \(String(text)); child: \(String(child))}>"
            }
        }

        init(name: String, child: Node?, text: String) {
            self.text = text

            super.init(name: name, child: child)
        }
    }
}