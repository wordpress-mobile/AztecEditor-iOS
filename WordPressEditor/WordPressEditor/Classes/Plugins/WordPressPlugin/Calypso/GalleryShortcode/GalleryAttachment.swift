import Aztec

class GalleryAttachment: MediaAttachment {    
    enum Order: String {
        case asc = "ASC"
        case desc = "DESC"
    }
    
    enum OrderBy: String {
        case menu = "menu_order"
        case title = "title"
        case postDate = "post_date"
        case rand = "rand"
        case ID = "ID"
    }
    
    var columns: Int?
    var ids: [Int]?
    var order: Order?
    var orderBy: OrderBy?
}
