import Foundation
import UIKit


public protocol AztecFormatBarDelegate : NSObjectProtocol
{
    func toggleBold()
    func toggleItalic()
    func toggleUnderline()
    func toggleStrikethrough()
    func toggleOrderedList()
    func toggleUnorderedList()
    func toggleBlockquote()
    func toggleLink()
    func insertImage()
}
