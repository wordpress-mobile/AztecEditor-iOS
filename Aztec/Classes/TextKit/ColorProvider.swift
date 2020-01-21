import Foundation
import UIKit

/// A class that provides colors to the formatter in TextKit.
/// By default only the standard html colors are provided, but new color can be added by using the `add(namedColors:)` method.
public class ColorProvider {


    private init() {

    }

    public static var shared = ColorProvider()

    private lazy var htmlColors: [String: UIColor] = {
        guard let colorDataURL = Bundle.aztecBundle.url(forResource: "html_colors", withExtension: "json"),
            let data = try? Data(contentsOf: colorDataURL),
            let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
            let colorDict = object as? [String: String] else {
                return [String:UIColor]()
        }

        return colorDict.compactMapValues { UIColor(hexString: $0) }
    }()

    private var extraColors = [String:UIColor]()

    /// Adds extra named colors to be used by the `color(named:)` method.
    ///  If there is a name collision, the value in the added dictionary will overwrite the current color.
    /// - Parameter namedColors: a dictionary of colors keyed by name
    public func add(namedColors: [String: UIColor]) {
        extraColors.merge(namedColors) { (base, other) -> UIColor in
            return other
        }
    }

    /// Returns a color designated by name or nil if the name is not available
    ///  By default the the color available are the ones defined in the HTML specification: https://www.w3schools.com/colors/colors_names.asp
    /// - Parameter name: the name of the color
    public func color(named name: String) -> UIColor? {
        if let color = htmlColors[name.lowercased()] {
            return color
        }

        return extraColors[name]
    }

    public lazy var codeBackgroungColor: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondarySystemBackground
        } else {
            return .lightGray
        }
    }()
}
