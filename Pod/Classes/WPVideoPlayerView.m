#import "WPVideoPlayerView.h"

@import AVFoundation;

static NSString *playerItemContext = @"ItemStatusContext";


@interface WPVideoPlayerView()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) UIToolbar *controlToolbar;

@end

@implementation WPVideoPlayerView

static NSString *tracksKey = @"tracks";

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    [self commonInit];
    return self;
}

- (void)commonInit {
    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer: self.player];
    [self.layer addSublayer: self.playerLayer];
    [self addSubview:self.controlToolbar];
}

- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath: @"status"];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self.player pause];
    _asset = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    self.controlToolbar.frame = CGRectMake(0, self.frame.size.height - 44, self.frame.size.width, 44);
}

- (UIToolbar *)controlToolbar {
    if (_controlToolbar) {
        return _controlToolbar;
    }
    _controlToolbar = [[UIToolbar alloc] init];
    [self updateControlToolbar];
    return _controlToolbar;
}

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    self.asset = asset;
}

- (void)setAsset:(AVAsset *)asset {
    [self.playerItem removeObserver:self forKeyPath: @"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _asset = asset;
    self.playerItem = [[AVPlayerItem alloc] initWithAsset: _asset];

    [self.playerItem addObserver:self
                      forKeyPath: @"status"
                         options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                         context:&playerItemContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    [self.player replaceCurrentItemWithPlayerItem: self.playerItem];
    [self play];
}


- (void)playerItemDidReachEnd:(AVPlayerItem *)playerItem {
    if (self.loop) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
    }
    if (self.delegate) {
        [self.delegate videoPlayerViewFinish:self];
    }
    [self updateControlToolbar];
}

- (void)play {
    [self.player play];
    [self updateControlToolbar];
}

- (void)pause {
    [self.player pause];
    [self updateControlToolbar];
}

- (void)togglePlayPause {
    if ([self.player timeControlStatus] == AVPlayerTimeControlStatusPaused) {
        if (CMTimeCompare(self.player.currentItem.currentTime, self.player.currentItem.duration) == 0) {
            [self.player seekToTime:kCMTimeZero];
        }
        [self play];
    } else {
        [self pause];
    }
}

- (void)updateControlToolbar {
    UIBarButtonSystemItem playPauseButton = [self.player timeControlStatus] == AVPlayerTimeControlStatusPaused ? UIBarButtonSystemItemPlay : UIBarButtonSystemItemPause;
    self.controlToolbar.items = @[
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:playPauseButton target:self action:@selector(togglePlayPause)],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]
                           ];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    // Only handle observations for the playerItemContext
    if (context != &playerItemContext) {
        [super observeValueForKeyPath: keyPath
                             ofObject: object
                               change: change
                              context: context];
        return;
    }

    if ( [keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status;
        NSNumber *statusNumber = change[NSKeyValueChangeNewKey];
        // Get the status change from the change dictionary
        if (statusNumber) {
            status = (AVPlayerItemStatus)[statusNumber intValue];
        } else {
            status = AVPlayerItemStatusUnknown;
        }

        // Switch over the status
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:{
                // Player item is ready to play.
                if (self.delegate) {
                    [self.delegate videoPlayerViewStarted:self];
                }
            }
                break;
            case AVPlayerItemStatusFailed: {
                // Player item failed. See error.
                NSError *error = [self.playerItem error];
                if (self.delegate) {
                    [self.delegate videoPlayerView:self didFailWithError: error];
                }
            }
                break;
            case AVPlayerItemStatusUnknown:
                // Player item is not yet ready.
                return;
                break;
        }
    }
}

@end

