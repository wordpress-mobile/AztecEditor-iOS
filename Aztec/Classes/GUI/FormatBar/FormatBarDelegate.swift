import Foundation
import UIKit


public protocol FormatBarDelegate : NSObjectProtocol
{
    func handleActionForIdentifier(identifier: String)
}
