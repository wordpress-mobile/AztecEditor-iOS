import Foundation
import UIKit

public class FontProvider {

    private init() {

    }

    public static var shared = FontProvider()

    public lazy var monospaceFont: UIFont = {
        let baseFont = UIFont(descriptor:UIFontDescriptor(name: "Menlo", size: 14), size:14)
        let font: UIFont
        font = UIFontMetrics.default.scaledFont(for: baseFont)
        return font
    }()

    public lazy var defaultFont: UIFont = {
        let baseFont = UIFont.systemFont(ofSize: 14)
        let font: UIFont
        font = UIFontMetrics.default.scaledFont(for: baseFont)        
        return font
    }()
}
