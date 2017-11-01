#import "WPVideoPlayerView.h"

@import AVFoundation;
#import "WPDateTimeHelpers.h"

static NSString *playerItemContext = @"ItemStatusContext";


@interface WPVideoPlayerView()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) UIToolbar *controlToolbar;
@property (nonatomic, strong) UIBarButtonItem *videoDurationButton;
@property (nonatomic, strong) UILabel *videoDurationLabel;
@property (nonatomic, strong) id timeObserver;

@end

@implementation WPVideoPlayerView

static NSString *tracksKey = @"tracks";
static NSString *timeFormatString = @"%@ / %@";
static CGFloat toolbarHeight = 44;

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

    __weak __typeof__(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:nil usingBlock:^(CMTime time) {
        [weakSelf updateVideoDuration];
    }];
}

- (void)dealloc {
    [_playerItem removeObserver:self forKeyPath: @"status"];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [_player removeTimeObserver:self.timeObserver];
    [_player pause];
    _asset = nil;
    _player = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
    CGFloat position = self.controlToolbarHidden ? 0 : toolbarHeight;
    self.controlToolbar.frame = CGRectMake(0, self.frame.size.height - position, self.frame.size.width, toolbarHeight);
}

- (UIToolbar *)controlToolbar {
    if (_controlToolbar) {
        return _controlToolbar;
    }
    _controlToolbar = [[UIToolbar alloc] init];
    _controlToolbar.hidden = YES;
    _controlToolbar.tintColor = [UIColor whiteColor];
    _controlToolbar.barStyle = UIBarStyleBlack;
    _controlToolbar.translucent = YES;
    [self updateControlToolbar];
    return _controlToolbar;
}

- (UIBarButtonItem *)videoDurationButton {
    if (_videoDurationButton) {
        return _videoDurationButton;
    }
    _videoDurationButton = [[UIBarButtonItem alloc] initWithCustomView:self.videoDurationLabel];
    _videoDurationButton.enabled = NO;
    return _videoDurationButton;
}

- (UILabel *)videoDurationLabel {
    if (_videoDurationLabel) {
        return _videoDurationLabel;
    }

    _videoDurationLabel = [UILabel new];
    _videoDurationLabel.textColor = [UIColor whiteColor];
    _videoDurationLabel.font = [UIFont monospacedDigitSystemFontOfSize:14.0 weight: UIFontWeightBold];
    _videoDurationLabel.adjustsFontSizeToFitWidth = NO;
    _videoDurationLabel.textAlignment = NSTextAlignmentRight;
    _videoDurationLabel.lineBreakMode = NSLineBreakByTruncatingTail;

    // Fix the label to the widest size we want to show, so it doesn't
    // resize itself and move around as we update the content
    _videoDurationLabel.text = [NSString stringWithFormat:timeFormatString, @"0:00:00", @"0:00:00"];
    [_videoDurationLabel sizeToFit];

    return _videoDurationLabel;
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
    if (self.shouldAutoPlay) {
        [self play];
    }
}


- (void)playerItemDidReachEnd:(AVPlayerItem *)playerItem {
    if (self.loop) {
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
    }
    if (self.delegate) {
        [self.delegate videoPlayerViewFinish:self];
    }
    [self updateControlToolbarVideoEnded:!self.loop];
}

- (void)play {
    [self.player play];
    [self updateControlToolbar];
    [self updateVideoDuration];
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

- (void)setControlToolbarHidden:(BOOL)hidden animated:(BOOL)animated {
    CGFloat animationDuration = animated ? UINavigationControllerHideShowBarDuration : 0;
    if (!hidden) {
        self.controlToolbar.hidden = hidden;
    }
    [UIView animateWithDuration:animationDuration animations:^{
        CGFloat position = hidden ? 0 : self.controlToolbar.frame.size.height;
        self.controlToolbar.frame = CGRectMake(0, self.frame.size.height - position, self.frame.size.width, toolbarHeight);
    } completion:^(BOOL finished) {
        self.controlToolbar.hidden = hidden;
    }];
}

- (void)setControlToolbarHidden:(BOOL)hidden {
    [self setControlToolbarHidden:hidden animated:NO];
}

- (BOOL)controlToolbarHidden {
    return self.controlToolbar.hidden;
}

- (void)updateControlToolbar {
    [self updateControlToolbarVideoEnded:NO];
}
- (void)updateControlToolbarVideoEnded:(BOOL)videoEnded{
    UIBarButtonSystemItem playPauseButton = [self.player timeControlStatus] == AVPlayerTimeControlStatusPaused || videoEnded ? UIBarButtonSystemItemPlay : UIBarButtonSystemItemPause;

    self.controlToolbar.items = @[
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil],
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:playPauseButton target:self action:@selector(togglePlayPause)],
                                  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                  self.videoDurationButton,
                                  ];
}

- (void)updateVideoDuration {
    AVPlayerItem *playerItem = self.player.currentItem;
    if (!playerItem || playerItem.status != AVPlayerItemStatusReadyToPlay) {
        return;
    }
    double totalSeconds = CMTimeGetSeconds(playerItem.duration);
    double currentSeconds = CMTimeGetSeconds(playerItem.currentTime);
    NSString *totalDuration = [WPDateTimeHelpers stringFromTimeInterval:totalSeconds];
    NSString *currentDuration = [WPDateTimeHelpers stringFromTimeInterval:currentSeconds];
    self.videoDurationLabel.text = [NSString stringWithFormat:timeFormatString, currentDuration, totalDuration];
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
        if (statusNumber != nil) {
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self updateVideoDuration];
                    });
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

