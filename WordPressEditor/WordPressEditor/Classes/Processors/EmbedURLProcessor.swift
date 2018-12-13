import Foundation

public struct EmbedURLProcessor{

    let url: URL

    init(url: URL){
        self.url = url
    }

    public var isValidEmbed: Bool{

        return isYouTubeEmbed
            || isVimeoEmbed
            || isTwitterEmbed
            || isFlickrEmbed
            || isIssuuEmbed
            || isInstagramEmbed
            || isFacebookEmbed
    }

    /// Tests the url to see if it's a valid YouTube URL.
    ///
    /// Supports these formats:
    ///  - Watch URL
    ///  - Embed URL
    ///  - Short URL
    ///
    public var isYouTubeEmbed: Bool {

        return matches(anyOf: [
            regex("^https?://(www.|m.)?youtube.com/(watch\\?v=|embed/)[0-9|a-z|A-Z|_|-]+$"),  // Full URL
            regex("^https?://youtu.be/[0-9|a-z|A-Z|_|-]+$"),                                  // Short URL
            regex("^https?://((m|www)\\.)?youtube\\.com/playlist[\\S]+$"),                    // Playlist URL
            regex("^https?://((m|www)\\.)?youtube\\.com/playlist[\\S]+$"),                    // Playlist URL
        ])
    }

    /// Tests the url to see if it's a valid Vimeo URL.
    ///
    /// Supports these formats:
    ///  - Watch URL
    ///  - Channel URL
    ///  - Embedded Player URL
    ///
    public var isVimeoEmbed: Bool {

        return matches(anyOf: [
            regex("^https?://vimeo.com/[0-9]+") ,                            // Watch
            regex("^https?://vimeo.com/channels/[0-9|a-z|A-Z]+/[0-9]+$"),    // Channel
            regex("^https://player.vimeo.com/video/[0-9]+$"),                // Player
        ])
    }

    /// Tests the url to see if it's a valid Twitter URL.
    ///
    /// Supports these formats:
    ///  - Tweet
    ///  - Profile
    ///  - Likes
    ///  - List
    ///  - Moment

    public var isTwitterEmbed: Bool {

        return matches(anyOf: [
            regex("https?://(www\\.)?twitter\\.com/\\w{1,15}/status(es)?/[\\S]+$"),   // Status
            regex("https?://(www\\.)?twitter\\.com/\\w{1,15}$"),                      // Profile
            regex("https?://(www\\.)?twitter\\.com/\\w{1,15}/likes$"),                // Likes
            regex("https?://(www\\.)?twitter\\.com/\\w{1,15}/lists/[\\S]+$"),         // List
            regex("https?://(www\\.)?twitter\\.com/i/moments/[\\S]+$"),               // Moments
        ])
    }

    /// Tests the url to see if it's a valid Flickr URL.
    ///
    /// Supports these formats:
    ///  - Photo URL
    ///  - Gallery URL
    ///  - Flic.kr short URLs (photos and galleries)
    ///
    public var isFlickrEmbed: Bool {
        return matches(regex("^https?://(www.)?(flickr.com|flic\\.kr)/(photos|p|s)/[\\S]+$"))
    }

    /// Tests the url to see if it's a valid Issuu URL.
    public var isIssuuEmbed: Bool {
        return matches(regex("^https?://(www\\.)?issuu\\.com/.+/docs/[\\S]+$"))
    }

    /// Tests the url to see if it's a valid Instagram URL.
    public var isInstagramEmbed: Bool {
        return matches(regex("^https?://(www\\.)?instagr(\\.am|am\\.com)/p/[\\S]+$"))
    }


    /// Tests the url to see if it's a valid Facebook URL.
    ///
    /// Supports these formats:
    ///  - Post URL
    ///  - Photo URL
    ///  - Note URL
    ///  - Video URL
    ///
    public var isFacebookEmbed: Bool {
        return matches(anyOf: [
            regex("https?://www\\.facebook\\.com/.*/posts/[\\S]+$"),                    // Post
            regex("https?://www\\.facebook\\.com/.*/photos/[\\S]+$"),                   // Photo
            regex("https?://www\\.facebook\\.com/notes/[\\S]+$"),                       // Note
            regex("https?://www\\.facebook\\.com/.*/videos/[\\S]+$"),                   // Video
        ])
    }

    private func regex(_ pattern: String) -> NSRegularExpression {
        return try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    private func matches(anyOf regexes: [NSRegularExpression]) -> Bool{
        return regexes.first{ matches($0) } != nil
    }

    private func matches(_ regex: NSRegularExpression) -> Bool {
        let urlRange = NSMakeRange(0, url.absoluteString.lengthOfBytes(using: .utf8))
        let urlString = url.absoluteString

        return !regex.matches(in: urlString, options: [], range: urlRange).isEmpty
    }
}
