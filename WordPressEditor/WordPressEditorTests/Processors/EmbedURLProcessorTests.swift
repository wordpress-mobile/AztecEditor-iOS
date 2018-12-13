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
        //With underscores!
        assert(EmbedURLProcessor(url: url("https://www.youtube.com/watch?v=Ms5mi_xADJw")).isYouTubeEmbed)
        assert(EmbedURLProcessor(url: url("https://youtu.be/Ms5mi_xADJw")).isYouTubeEmbed)
        //With dashes!
        assert(EmbedURLProcessor(url: url("https://www.youtube.com/watch?v=WVbQ-oro7FQ")).isYouTubeEmbed)
        assert(EmbedURLProcessor(url: url("https://youtu.be/WVbQ-oro7FQ")).isYouTubeEmbed)
        //The mobile version!
        assert(EmbedURLProcessor(url: url("https://m.youtube.com/watch?v=gqEtq34dSUo")).isYouTubeEmbed)
        //A playlist!
        assert(EmbedURLProcessor(url: url("https://www.youtube.com/playlist?list=PLQFhxUeNFfdJsoUnGQ8ucK_TIJsosmSXm")).isYouTubeEmbed)
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

    func testThatValidTwitterURLsWork() {
        assert(EmbedURLProcessor(url: url("https://twitter.com/WordPressiOS")).isTwitterEmbed)
        assert(EmbedURLProcessor(url: url("https://twitter.com/WordPressiOS/likes")).isTwitterEmbed)

        assert(EmbedURLProcessor(url: url("https://twitter.com/WordPressiOS/status/999307616936394755")).isTwitterEmbed)
        assert(EmbedURLProcessor(url: url("https://twitter.com/WordPressiOS/statuses/999307616936394755")).isTwitterEmbed)
        assert(EmbedURLProcessor(url: url("https://twitter.com/WordPressiOS/status/999307616936394755?s=19")).isTwitterEmbed)

        assert(EmbedURLProcessor(url: url("https://twitter.com/CNN/lists/inauguration-2017")).isTwitterEmbed)
        assert(EmbedURLProcessor(url: url("https://twitter.com/i/moments/823549915695611904")).isTwitterEmbed)
    }

    func testThatValidFlickrPhotoURLsWork() {
        assert(EmbedURLProcessor(url: url("https://www.flickr.com/photos/pware/32732270066")).isFlickrEmbed)
        assert(EmbedURLProcessor(url: url("https://www.flickr.com/photos/rafaberlanga/45345306675/in/explore-2018-12-10/")).isFlickrEmbed)

        //Short URLs
        assert(EmbedURLProcessor(url: url("http://flic.kr/p/23MvrtD")).isFlickrEmbed)
    }

    func testThatValidFlickrAlbumURLsWork() {
        assert(EmbedURLProcessor(url: url("https://www.flickr.com/photos/22020982@N05/albums/72157690359747511")).isFlickrEmbed)
        assert(EmbedURLProcessor(url: url("https://www.flickr.com/photos/22020982@N05/albums/72157690359747511")).isFlickrEmbed)

        //Short URLs
        assert(EmbedURLProcessor(url: url("http://flic.kr/s/aHsmaJFWKa")).isFlickrEmbed)
    }

    func testThatValidIssuuURLsWork() {
        assert(EmbedURLProcessor(url: url("https://issuu.com/magazineemma/docs/emma_fall_issue/52")).isIssuuEmbed)
    }

    func testThatValidInstagramURLsWork() {
        assert(EmbedURLProcessor(url: url("https://www.instagram.com/p/Bc3Ex6nFoKo/")).isInstagramEmbed)
    }

    func testThatValidFacebookURLsWork() {
        assert(EmbedURLProcessor(url: url("https://www.facebook.com/WordPress/posts/10156605256927911")).isFacebookEmbed)
        assert(EmbedURLProcessor(url: url("https://www.facebook.com/WordPress/photos/a.111006762910/111008012910/?type=3&theater")).isFacebookEmbed)
        assert(EmbedURLProcessor(url: url("https://www.facebook.com/notes/mark-zuckerberg/a-letter-to-our-daughter/10153375081581634/")).isFacebookEmbed)
        assert(EmbedURLProcessor(url: url("https://www.facebook.com/WordPress/videos/10154702401472911/")).isFacebookEmbed)
    }

    private func url(_ string: String) -> URL{
        return URL(string: string)!
    }
}
