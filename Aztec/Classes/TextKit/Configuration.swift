import Foundation

public final class Configuration {

    public static var headersWithBoldTrait = false

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
