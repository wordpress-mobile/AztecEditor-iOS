import Foundation


// MARK: - UnsupportedHTML
//
class UnsupportedHTML: NSObject {

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
        guard let representations = aDecoder.decodeObject(forKey: Keys.representations) as? [HTMLElementRepresentation] else {
            return nil
        }

        self.representations = representations
    }
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
