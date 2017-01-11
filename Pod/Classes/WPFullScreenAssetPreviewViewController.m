#import "WPFullScreenAssetPreviewViewController.h"

@interface WPFullScreenAssetPreviewViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation WPFullScreenAssetPreviewViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.activityIndicatorView];
}

- (void)viewWillLayoutSubviews {
    self.imageView.frame = self.view.frame;
    self.activityIndicatorView.center = self.view.center;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.activityIndicatorView startAnimating];
    [self fetchAsset];
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
    [_imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnImage:)]];
    return _imageView;
}

- (UIActivityIndicatorView *)activityIndicatorView
{
    if (_activityIndicatorView) {
        return _activityIndicatorView;
    }

    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

    return _activityIndicatorView;
}

- (void)fetchAsset
{
    if (self.asset == nil) {
        self.imageView.image = nil;
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    [self.asset imageWithSize:CGSizeZero completionHandler:^(UIImage *result, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            return;
        }
        [strongSelf.activityIndicatorView stopAnimating];
        strongSelf.imageView.image = result;
    }];
}

- (void)handleTapOnImage:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.navigationController setNavigationBarHidden:!self.navigationController.isNavigationBarHidden animated:YES];
    }
}

@end
