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
    self.view.backgroundColor = [UIColor redColor];
    [self setupMediaPickerViewController];
}

- (void)setupMediaPickerViewController {
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.privateDataSource = [[WPPHAssetDataSource alloc] init];    
    self.mediaPicker.dataSource = self.privateDataSource;

    [self addChildViewController:self.mediaPicker];
    [self overridePickerTraits];
    
    self.mediaPicker.view.frame = self.view.bounds;
    self.mediaPicker.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mediaPicker.view];
    [self.mediaPicker didMoveToParentViewController:self];
    self.mediaPicker.collectionView.alwaysBounceHorizontal = NO;

    self.mediaToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.mediaToolbar.items = @[
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(mediaCanceled:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(mediaSelected:)]
                      ];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configureCollectionView];
}

- (void)configureCollectionView {
    CGFloat numberOfPhotosForLine = 4;
    CGFloat photoSpacing = 1.0f;
    CGFloat topInset = 5.0f;
    CGFloat bottomInset = 10.0f;
    CGFloat frameHeightWidth = self.view.frame.size.width;
    CGFloat minFrameWidth = MIN(frameHeightWidth, frameHeightWidth);

    CGFloat cellSize = [self.mediaPicker cellSizeForPhotosPerLineCount:numberOfPhotosForLine
                                                          photoSpacing:photoSpacing
                                                            frameWidth:minFrameWidth];

    // Check the actual width of the content based on the computed cell size
    // How many photos are we actually fitting per line?
    CGFloat totalSpacing = (numberOfPhotosForLine - 1) * photoSpacing;
    numberOfPhotosForLine = floorf((frameHeightWidth - totalSpacing) / cellSize);

    CGFloat contentWidth = (numberOfPhotosForLine * cellSize) + totalSpacing;

    // If we have gaps in our layout, adjust to fit
    if (contentWidth < frameHeightWidth) {
        cellSize = [self.mediaPicker cellSizeForPhotosPerLineCount:numberOfPhotosForLine
                                                      photoSpacing:photoSpacing
                                                        frameWidth:frameHeightWidth];
    }
    
    // Init and configure collection view layout
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = CGSizeMake(cellSize, cellSize);
    layout.minimumInteritemSpacing = photoSpacing;
    layout.minimumLineSpacing = photoSpacing;
    layout.sectionInset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0);

    self.mediaPicker.options.cameraPreviewSize = CGSizeMake(1.5*cellSize, 1.5*cellSize);
    self.mediaPicker.collectionView.collectionViewLayout = layout;
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

- (void)setDataSource:(id<WPMediaCollectionDataSource>)dataSource {
    self.mediaPicker.dataSource = dataSource;
}

- (id<WPMediaCollectionDataSource>)dataSource {
    return self.mediaPicker.dataSource;
}

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


@end
