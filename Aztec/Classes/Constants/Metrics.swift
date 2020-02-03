import CoreGraphics
import Foundation

/// A collection of constants and metrics shared between the Aztec importer
/// and the editor.
///
public enum Metrics {

    public static var defaultIndentation = CGFloat(12)
    public static var maxIndentation = CGFloat(200)
    public static var listTextIndentation = CGFloat(12)
    public static var listTextCharIndentation = CGFloat(8)
    public static var listMinimumIndentChars = 3
    public static var tabStepInterval = 4
    public static var tabStepCount = 12
    public static var paragraphSpacing = CGFloat(6)
}
