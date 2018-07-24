import Foundation
import Aztec

/// Class to facilitate decoding of Gutenberg comments data from Element attributes
///
class GutenbergAttributeDecoder {

    // MARK: - Attribute Data

    func attribute(_ gutenbergAttribute: GutenbergAttribute, from element: ElementNode) -> String? {
        guard let attribute = element.attribute(named: gutenbergAttribute.rawValue),
            let opener = decode(attribute) else {
                return nil
        }
        
        return opener
    }

    // MARK: - Base64 Decoding

    private func decode(_ attribute: Attribute) -> String? {
        guard let base64Gutenblock = attribute.value.toString() else {
            return nil
        }

        return decode(base64Gutenblock: base64Gutenblock)
    }

    private func decode(base64Gutenblock: String) -> String {
        let data = Data(base64Encoded: base64Gutenblock)!
        return String(data: data, encoding: .utf16)!
    }
}
