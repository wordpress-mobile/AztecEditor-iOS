import XCTest
@testable import Aztec

class UIImageResizeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResizingImageWorks() {
        let bundle = Bundle(for: type(of: self))
        
        guard let image = UIImage(named: "aztec", in: bundle, compatibleWith: nil) else {
            XCTFail()
            return
        }
        
        let rectSize = CGSize(width: 400, height: 400)
        let maxImageSize = CGSize(width: 200, height: 200)
        
        let resizedImage = image.resizedImageWithinRect(rectSize: rectSize, maxImageSize: maxImageSize, color: UIColor.blue)
        
        guard let resizedPNGRepresentation = resizedImage.pngData() else {
            XCTFail()
            return
        }
        
        let fileName: String = {
            if UIScreen.main.scale == 3 {
                return "UIImageResizeImage1_3x.png"
            } else if UIScreen.main.scale == 2 {
                return "UIImageResizeImage1_2x.png"
            }
            
            // We no longer support 1x
            fatalError()
        }()
        
        guard let url = bundle.url(forResource: fileName, withExtension: "dat", subdirectory: nil),
            let expectedPNGRepresentation = try? Data(contentsOf: url, options: []) else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(resizedPNGRepresentation, expectedPNGRepresentation)
    }
    
    func testResizingImageWorks2() {
        let bundle = Bundle(for: type(of: self))
        
        guard let image = UIImage(named: "aztec", in: bundle, compatibleWith: nil) else {
            XCTFail()
            return
        }
        
        let rectSize = CGSize(width: 200, height: 400)
        let maxImageSize = CGSize(width: 200, height: 400)
        
        let resizedImage = image.resizedImageWithinRect(rectSize: rectSize, maxImageSize: maxImageSize, color: UIColor.blue)
        
        guard let resizedPNGRepresentation = resizedImage.pngData() else {
            XCTFail()
            return
        }
        
        let fileName: String = {
            if UIScreen.main.scale == 3 {
                return "UIImageResizeImage2_3x.png"
            } else if UIScreen.main.scale == 2 {
                return "UIImageResizeImage2_2x.png"
            }
            
            // We no longer support 1x
            fatalError()
        }()
        
        guard let url = bundle.url(forResource: fileName, withExtension: "dat", subdirectory: nil),
            let expectedPNGRepresentation = try? Data(contentsOf: url, options: []) else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(resizedPNGRepresentation, expectedPNGRepresentation)
    }
    
    func testResizingImageWithoutSizeChangeReturnsSameImage() {
        let bundle = Bundle(for: type(of: self))
        
        guard let image = UIImage(named: "aztec", in: bundle, compatibleWith: nil) else {
            XCTFail()
            return
        }
        
        let newSize = image.size
        let resizedImage = image.resizedImage(newSize: newSize, color: UIColor.blue)
        
        XCTAssertEqual(image, resizedImage)
    }
}
