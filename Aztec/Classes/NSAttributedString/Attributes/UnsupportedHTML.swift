import Foundation


// MARK: - UnsupportedHTML
//
class UnsupportedHTML: NSObject, NSSecureCoding {

    /// ElementRepresentation for Unsupported HTML
    ///
    let representations: [HTMLElementRepresentation]

    /// Default Initializer
    ///
    init(representations: [HTMLElementRepresentation]) {
        self.representations = representations
    }

    /// Required Initializers
    ///
    public required init?(coder aDecoder: NSCoder) {
        let representations: [HTMLElementRepresentation]?
        if #available(iOS 14.0, *) {
            representations = aDecoder.decodeArrayOfObjects(ofClass: HTMLElementRepresentation.self, forKey: Keys.representations)
        } else {
            representations = aDecoder.decodeObject(of: NSArray.self, forKey: Keys.representations) as? [HTMLElementRepresentation]
        }

        guard let representations else {
            return nil
        }
        self.representations = representations
    }

    open class var supportsSecureCoding: Bool { true }
}


// MARK: - NSCoding Conformance
//
extension UnsupportedHTML: NSCoding {

    struct Keys {
        static let representations = "representations"
    }

    open func encode(with aCoder: NSCoder) {
        aCoder.encode(representations, forKey: Keys.representations)
    }
}
