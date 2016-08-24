import Foundation


// Encompases the whole text list. Analogous to a UL or OL tag
class TextList
{
    static let attributeName = "TextListAttributeName"
    var type = TextListType.Ordered
    var parentList: TextList?
}


// Encompases the entirety of a single text list item. Analogous to an LI tag
class TextListItem
{
    static let attributeName = "TextListItemAttributeName"

}


// Encompases the range of the bullet/number + tab.
class TextListItemMarker
{
    static let attributeName = "TextListItemMarkerAttributeName"
}


enum TextListType
{
    case Ordered
    case Unordered
}