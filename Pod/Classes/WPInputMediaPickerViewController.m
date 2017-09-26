#import "WPInputMediaPickerViewController.h"
#import "WPPHAssetDataSource.h"

@interface WPInputMediaPickerViewController()

@property (nonatomic, strong) WPMediaPickerViewController *mediaPicker;
@property (nonatomic, strong) UIToolbar *mediaToolbar;
@property (nonatomic, strong) id<WPMediaCollectionDataSource> privateDataSource;

@end

@implementation WPInputMediaPickerViewController

- (instancetype _Nonnull )initWithOptions:(WPMediaPickerOptions *_Nonnull)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:[options copy]];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:[WPMediaPickerOptions new]];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _mediaPicker = [[WPMediaPickerViewController alloc] initWithOptions:[WPMediaPickerOptions new]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
    [self setupMediaPickerViewController];
}

- (void)setupMediaPickerViewController {
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.privateDataSource = [[WPPHAssetDataSource alloc] init];    
    self.mediaPicker.dataSource = self.privateDataSource;

    [self addChildViewController:self.mediaPicker];
    [self overridePickerTraits];
    
    self.mediaPicker.view.frame = self.view.bounds;
    self.mediaPicker.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mediaPicker.view];
    
    NSLayoutAnchor *leadingAnchor = self.view.leadingAnchor;
    NSLayoutAnchor *trailingAnchor = self.view.trailingAnchor;

    if (@available(iOS 11.0, *)) {
        leadingAnchor = self.view.safeAreaLayoutGuide.leadingAnchor;
        trailingAnchor = self.view.safeAreaLayoutGuide.trailingAnchor;
    }

    [NSLayoutConstraint activateConstraints:
     @[
       [self.mediaPicker.view.leadingAnchor constraintEqualToAnchor:leadingAnchor],
       [self.mediaPicker.view.trailingAnchor constraintEqualToAnchor:trailingAnchor],
       [self.mediaPicker.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
       [self.mediaPicker.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
       ]
     ];

    [self.mediaPicker didMoveToParentViewController:self];
    self.view.backgroundColor = [UIColor whiteColor];
    self.mediaToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.mediaToolbar.items = @[
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(mediaCanceled:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(mediaSelected:)]
                      ];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self overridePickerTraits];
}

- (void)overridePickerTraits
{
    // Due to an inputView being displayed in its own window, the force touch peek transition
    // doesn't display correctly. Because of this, we'll disable it for the input picker thus forcing
    // long touch to be used instead.
    UITraitCollection *traits = [UITraitCollection traitCollectionWithForceTouchCapability:UIForceTouchCapabilityUnavailable];
    [self setOverrideTraitCollection:[UITraitCollection traitCollectionWithTraitsFromCollections:@[self.traitCollection, traits]] forChildViewController:self.mediaPicker];
}

#pragma mark - WPMediaCollectionDataSource

- (void)setDataSource:(id<WPMediaCollectionDataSource>)dataSource {
    self.mediaPicker.dataSource = dataSource;
}

- (id<WPMediaCollectionDataSource>)dataSource {
    return self.mediaPicker.dataSource;
}

#pragma mark - WPMediaPickerViewControllerDelegate

- (void)setMediaPickerDelegate:(id<WPMediaPickerViewControllerDelegate>)mediaPickerDelegate {
    self.mediaPicker.mediaPickerDelegate = mediaPickerDelegate;
}

- (id<WPMediaPickerViewControllerDelegate>)mediaPickerDelegate {
    return self.mediaPicker.mediaPickerDelegate;
}

- (void)mediaSelected:(UIBarButtonItem *)sender {
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
        [self.mediaPickerDelegate mediaPickerController:self.mediaPicker didFinishPickingAssets:self.mediaPicker.selectedAssets];
        [self.mediaPicker resetState:NO];
    }
    
}

- (void)mediaCanceled:(UIBarButtonItem *)sender {
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.mediaPickerDelegate mediaPickerControllerDidCancel:self.mediaPicker];
        [self.mediaPicker resetState:NO];
    }
}

- (void)showCapture
{
    [self.mediaPicker showCapture];
}

@end
