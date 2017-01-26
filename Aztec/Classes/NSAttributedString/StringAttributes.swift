import Foundation

enum StringAttributeName: String {
    case controlCharacter = "Aztec.AttributeKeys.controlCharacter" // Value is ControlCharacterType
}

enum ControlCharacterType: String {
    case blockquoteCloser = "Aztec.ControlCharacterType.blockquoteCloser"
    case blockquoteOpener = "Aztec.ControlCharacterType.blockquoteOpener"
    case listItemCloser = "Aztec.ControlCharacterType.listItemCloser"
    case listItemOpener = "Aztec.ControlCharacterType.listItemOpener"
    case paragraphCloser = "Aztec.ControlCharacterType.paragraphCloser"
    
    static func closingControlCharacter(forNodeNamed nodeName: String) -> ControlCharacterType? {
        guard let elementType = Libxml2.StandardElementType(rawValue: nodeName) else {
            return nil
        }
        
        return closingControlCharacter(forStandardElementType: elementType)
    }
    
    static func closingControlCharacter(forStandardElementType elementType: Libxml2.StandardElementType) -> ControlCharacterType? {
        switch elementType {
        case .blockquote:
            return .blockquoteCloser
        case .li:
            return .listItemCloser
        case .p:
            return .paragraphCloser
        default:
            return nil
        }
    }
    
    static func openingControlCharacter(forNodeNamed nodeName: String) -> ControlCharacterType? {
        guard let elementType = Libxml2.StandardElementType(rawValue: nodeName) else {
            return nil
        }
        
        return openingControlCharacter(forStandardElementType: elementType)
    }
    
    static func openingControlCharacter(forStandardElementType elementType: Libxml2.StandardElementType) -> ControlCharacterType? {
        switch elementType {
        case .blockquote:
            return .blockquoteOpener
        case .li:
            return .listItemOpener
        default:
            return nil
        }
    }
}
