import Foundation

extension NSAttributedString {

    typealias ProcessDifferenceClosure = (NSRange, String, Any?, Any?) -> ()

    func enumerateAttributeDifferences(
        in range: NSRange,
        against targetAttributes: [String : Any],
        do processDifference: ProcessDifferenceClosure) {

        enumerateAttributes(in: range, options: [], using: { (attributes, subRange, stop) in
            NSAttributedString.enumerateAttributeDifferences(
                in: subRange,
                sourceAttributes: attributes,
                targetAttributes: targetAttributes,
                do: processDifference)
        })
    }

    static func enumerateAttributeDifferences(
        in range: NSRange,
        sourceAttributes: [String : Any],
        targetAttributes: [String : Any],
        do processDifference: ProcessDifferenceClosure) {

        let sourceKeys = Set(sourceAttributes.keys)
        let targetKeys = Set(targetAttributes.keys)
        let joinedKeys = sourceKeys.union(targetKeys)

        for key in joinedKeys {
            let sourceValue = sourceAttributes.contains(where: { return $0.key == key }) ? sourceAttributes[key] : nil
            let targetValue = targetAttributes.contains(where: { return $0.key == key }) ? targetAttributes[key] : nil

            processDifference(range, key, sourceValue, targetValue)
        }
    }
}
