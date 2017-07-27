import Foundation

/// Enum describing standard HTML attributes.
///
enum StandardHTMLAttribute: String {
    case style = "style"

    enum ValueType {
        case empty
        case string
        case inlineCss
    }

    /// Returns the
    func attributeValueType() -> ValueType {
        switch(self) {
        case .style:
            return .inlineCss
        }
    }
}
