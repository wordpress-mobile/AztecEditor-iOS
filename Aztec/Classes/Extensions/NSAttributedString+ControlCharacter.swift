import Foundation

extension NSAttributedString {

    func firstControlCharacter(inRange range: NSRange) -> ControlCharacterType? {

        var result: ControlCharacterType? = nil

        enumerateAttribute(ControlCharacterAttributeName, in: range) { (attributeValue, subRange, stop) in
            guard let attributeValue = attributeValue else {
                return
            }

            result = attributeValue as? ControlCharacterType
            stop.pointee = true
        }

        return result
    }

    func lastControlCharacter(inRange range: NSRange) -> ControlCharacterType? {

        var result: ControlCharacterType? = nil

        enumerateAttribute(ControlCharacterAttributeName, in: range, options: .reverse) { (attributeValue, subRange, stop) in
            guard let attributeValue = attributeValue else {
                return
            }

            result = attributeValue as? ControlCharacterType
            stop.pointee = true
        }

        return result
    }
}
