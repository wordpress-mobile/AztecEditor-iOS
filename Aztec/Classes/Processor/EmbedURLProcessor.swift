import Foundation

public struct EmbedURLProcessor{

    let url: URL

    init(url: URL){
        self.url = url
    }

    public var isValidEmbed: Bool{
        return isYouTubeEmbed || isVimeoEmbed
    }

    /// Tests the url to see if it's a valid YouTube URL.
    ///
    /// Supports these formats:
    ///  - Watch URL
    ///  - Embed URL
    ///  - Short URL
    ///
    public var isYouTubeEmbed: Bool {
        let longPattern = "^https?://(www.)?youtube.com/(watch\\?v=|embed/)[0-9|a-z|A-Z]+$"
        let long = try! NSRegularExpression(pattern: longPattern, options: [.caseInsensitive])

        let shortPattern = "^https?://youtu.be/[0-9|a-z|A-Z]+$"
        let short = try! NSRegularExpression(pattern: shortPattern, options: [.caseInsensitive])

        return matches(long) || matches(short)
    }

    /// Tests the url to see if it's a valid Vimeo URL.
    ///
    /// Supports these formats:
    ///  - Watch URL
    ///  - Channel URL
    ///  - Embedded Player URL
    ///
    public var isVimeoEmbed: Bool {
        let pattern = "^https?://vimeo.com/[0-9]+$"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])

        let channelPattern = "^https?://vimeo.com/channels/[0-9|a-z|A-Z]+/[0-9]+$"
        let channel = try! NSRegularExpression(pattern: channelPattern, options: [.caseInsensitive])

        let playerPattern = "^https://player.vimeo.com/video/[0-9]+$"
        let player = try! NSRegularExpression(pattern: playerPattern, options: [.caseInsensitive])

        return matches(regex) || matches(channel) || matches(player)
    }

    private func matches(_ regex: NSRegularExpression) -> Bool {
        let urlRange = NSMakeRange(0, url.absoluteString.lengthOfBytes(using: .utf8))
        let urlString = url.absoluteString

        return !regex.matches(in: urlString, options: [], range: urlRange).isEmpty
    }
}
