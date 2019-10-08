import Foundation
import UIKit

public class FontProvider {

    private init() {

    }

    static var shared = FontProvider()

    public lazy var monospaceFont: UIFont = {
        let baseFont = UIFont(descriptor:UIFontDescriptor(name: "Menlo", size: 14), size:14)
        let font: UIFont
        if #available(iOS 11.0, *) {
            font = UIFontMetrics.default.scaledFont(for: baseFont)
        } else {
            font = baseFont
        }
        return font
    }()

    public lazy var defaultFont: UIFont = {
        let baseFont = UIFont.systemFont(ofSize: 14)
        let font: UIFont
        if #available(iOS 11.0, *) {
            font = UIFontMetrics.default.scaledFont(for: baseFont)
        } else {
            font = baseFont
        }
        return font
    }()
}
