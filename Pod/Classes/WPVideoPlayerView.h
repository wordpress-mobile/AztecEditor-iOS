@import Foundation;
@import UIKit;

@class WPVideoPlayerView;

@protocol WPVideoPlayerViewDelegate

- (void)videoPlayerView:(WPVideoPlayerView *)playerView didFailedWithError:(NSError *)error;
 - (void)videoPlayerViewStarted:(WPVideoPlayerView *)playerView;
 - (void)videoPlayerViewFinish:(WPVideoPlayerView *)playerView;

@end

@interface WPVideoPlayerView: UIView


@property (nonatomic, assign) BOOL loop;

@property (nonatomic, weak) id<WPVideoPlayerViewDelegate> delegate;

@property (nonatomic, strong) NSURL *videoURL;

    
@end

