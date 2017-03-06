#import "CustomPreviewViewController.h"

@interface CustomPreviewViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation CustomPreviewViewController

- (instancetype)initWithAsset:(id<WPMediaAsset>)asset
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _asset = asset;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Preview";

    self.view.backgroundColor = [UIColor greenColor];

    [self addImageView];
    [self loadImage];
}

- (void)addImageView
{
    UIImageView *imageView = [UIImageView new];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:imageView];

    [NSLayoutConstraint activateConstraints:@[
                                              [imageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                              [imageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
                                              [imageView.widthAnchor constraintEqualToConstant:200],
                                              [imageView.heightAnchor constraintEqualToConstant:200],
                                              ]];

    self.imageView = imageView;
}

- (void)loadImage
{
    if ([self.asset assetType] == WPMediaTypeImage) {
        __weak __typeof__(self) weakSelf = self;
        [self.asset imageWithSize:CGSizeMake(200, 200) completionHandler:^(UIImage *result, NSError *error) {
            __typeof__(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.imageView.image = result;
            });
        }];
    }
}

- (CGSize)preferredContentSize
{
    return CGSizeMake(200, 200);
}

@end
