import Foundation


// MARK: - NSAttributedString: Stripping Attributes
//
extension NSAttributedString {

    /// Removes attributes of the specified Types, and returns a clean copy of the receiver.
    ///
    func stripAttributes(of kinds: [Any.Type]) -> NSAttributedString {
        guard let clean = mutableCopy() as? NSMutableAttributedString else {
            fatalError()
        }

        let range = clean.rangeOfEntireString
        clean.enumerateAttributes(in: range, options: []) { (attributes, range, _) in
            for (key, value) in attributes {
                let contained = kinds.contains(where: { kind in
                    return self.isObject(value, kindOf: kind)
                })

                if contained {
                    clean.removeAttribute(key, range: range)
                }
            }
        }

        return clean
    }

    /// Returns true if a given instance's kind matches with a specified type.
    ///
    private func isObject<T>(_ object: Any, kindOf type: T) -> Bool {
        return Swift.type(of: object) is T
    }
}
