import Foundation

public final class Configuration {

    public static var headersWithBoldTrait = false
    public static var useDefaultFont = false

    static var defaultBoldFormatter: AttributeFormatter {
        get {
            if headersWithBoldTrait {
                return BoldWithShadowForHeadingFormatter()
            } else {
                return BoldFormatter()
            }
        }
    }
}
