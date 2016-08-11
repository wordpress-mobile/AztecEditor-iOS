import Foundation


public class TextList : NSObject
{

    public private(set) var markerFormat: String

    public private(set) var listOptions: TextListOptions

    var startingItemNumber: Int = 0


    init(markerFormat format: String, options mask: Int) {
        self.markerFormat = ""
        self.listOptions = .Circle
        super.init()
    }


    func markerForItemNumber(itemNum: Int) -> String {
        return ""
    }

}


public enum TextListOptions
{
    case Circle
    case Decimal
}
