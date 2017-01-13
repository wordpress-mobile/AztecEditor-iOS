#import "WPFullScreenAssetPreviewViewController.h"

@import AVFoundation;
@import AVKit;

#import "WPVideoPlayerView.h"

@interface WPFullScreenAssetPreviewViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) WPVideoPlayerView *videoView;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation WPFullScreenAssetPreviewViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    UILayoutGuide *margins = self.view.layoutMarginsGuide;

    [self.view addSubview:self.imageView];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.imageView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.imageView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [self.imageView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.topAnchor].active = YES;
    [self.imageView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor].active = YES;

    [self.view addSubview:self.videoView];
    self.videoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.videoView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.videoView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [self.videoView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.topAnchor].active = YES;
    [self.videoView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor].active = YES;

    [self.view addSubview:self.activityIndicatorView];
    self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.activityIndicatorView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.activityIndicatorView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;

    [self showAsset];
}

- (UIImageView *)imageView
{
    if (_imageView) {
        return _imageView;
    }
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.backgroundColor = [UIColor blackColor];
    _imageView.userInteractionEnabled = YES;
    [_imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnAsset:)]];
    return _imageView;
}

- (WPVideoPlayerView *)videoView
{
    if (_videoView) {
        return _videoView;
    }
    _videoView = [[WPVideoPlayerView alloc] init];
    [_videoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnAsset:)]];
    return _videoView;
}


- (UIActivityIndicatorView *)activityIndicatorView
{
    if (_activityIndicatorView) {
        return _activityIndicatorView;
    }

    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

    return _activityIndicatorView;
}

- (void)showAsset
{
    self.imageView.hidden = YES;
    self.videoView.hidden = YES;
    if (self.asset == nil) {
        self.imageView.image = nil;
        self.videoView.videoURL = nil;
        return;
    }
    switch ([self.asset assetType]) {
        case WPMediaTypeImage:
            [self showImageAsset];
        break;
        case WPMediaTypeVideo:
            [self showVideoAsset];
        break;
    }
}

- (void)showImageAsset
{
    self.imageView.hidden = NO;
    [self.activityIndicatorView startAnimating];
    __weak __typeof__(self) weakSelf = self;
    [self.asset imageWithSize:CGSizeZero completionHandler:^(UIImage *result, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf.activityIndicatorView stopAnimating];
        if (error) {
            [self showError:error];
            return;
        }
        strongSelf.imageView.image = result;
    }];
}

- (void)showVideoAsset
{
    self.videoView.hidden = NO;
    [self.activityIndicatorView startAnimating];
    __weak __typeof__(self) weakSelf = self;
    [self.asset videoURLWithCompletionHandler:^(NSURL *url, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf.activityIndicatorView stopAnimating];
        if (error || url == nil) {
            [self showError:error];
            return;
        }
        self.videoView.videoURL = url;
    }];
}

- (void)showError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Media preview failed.", @"Alert title when there is issues loading an asset to preview.")
                                                                                  message:error.localizedDescription
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];

        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)handleTapOnAsset:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.navigationController setNavigationBarHidden:!self.navigationController.isNavigationBarHidden animated:YES];
    }
}

@end
