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
                guard kinds.contains(where: { type(of: value) == $0 }) else {
                    continue
                }

                clean.removeAttribute(key, range: range)
            }
        }

        return clean
    }
}
