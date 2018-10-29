import XCTest
@testable import WordPressEditor

class EmbedURLProcessorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testThatValidYouTubeWatchURLsWork() {
        //HTTPS, WWW
        assert(EmbedURLProcessor(url: url("https://www.youtube.com/watch?v=Z1BCujX3pw8")).isYouTubeEmbed)
        //HTTPS, no WWW
        assert(EmbedURLProcessor(url: url("https://youtube.com/watch?v=Z1BCujX3pw8")).isYouTubeEmbed)
        //HTTP, WWW
        assert(EmbedURLProcessor(url: url("http://www.youtube.com/watch?v=Z1BCujX3pw8")).isYouTubeEmbed)
    }

    func testThatValidYouTubeEmbedURLsWork() {
        //HTTPS, WWW
        assert(EmbedURLProcessor(url: url("https://www.youtube.com/embed/Z1BCujX3pw8")).isYouTubeEmbed)
        //HTTPS, no WWW
        assert(EmbedURLProcessor(url: url("https://youtube.com/embed/Z1BCujX3pw8")).isYouTubeEmbed)
        //HTTP, WWW
        assert(EmbedURLProcessor(url: url("http://www.youtube.com/embed/Z1BCujX3pw8")).isYouTubeEmbed)
    }

    func testThatValidYouTubeShortURLsWork() {
        //HTTPS
        assert(EmbedURLProcessor(url: url("https://youtu.be/Z1BCujX3pw8")).isYouTubeEmbed)
        //HTTP
        assert(EmbedURLProcessor(url: url("http://youtu.be/Z1BCujX3pw8")).isYouTubeEmbed)
    }

    func testThatValidVimeoURLsWork() {
        //HTTPS
        assert(EmbedURLProcessor(url: url("https://vimeo.com/295040990")).isVimeoEmbed)
        //HTTP
        assert(EmbedURLProcessor(url: url("http://vimeo.com/295040990")).isVimeoEmbed)

        //HTTPS – Channel
        assert(EmbedURLProcessor(url: url("https://vimeo.com/channels/staffpicks/290322470")).isVimeoEmbed)
        //HTTP – Channel
        assert(EmbedURLProcessor(url: url("http://vimeo.com/channels/staffpicks/290322470")).isVimeoEmbed)

        //HTTPS – Player
        assert(EmbedURLProcessor(url: url("https://player.vimeo.com/video/291598893")).isVimeoEmbed)
        //HTTP – Player
        assert(EmbedURLProcessor(url: url("https://player.vimeo.com/video/291598893")).isVimeoEmbed)
    }

    private func url(_ string: String) -> URL{
        return URL(string: string)!
    }
}
