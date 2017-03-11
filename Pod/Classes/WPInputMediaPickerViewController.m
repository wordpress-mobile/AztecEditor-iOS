#import "WPInputMediaPickerViewController.h"
#import "WPPHAssetDataSource.h"

@interface WPInputMediaPickerViewController()

@property (nonatomic, strong) WPMediaPickerViewController *mediaPicker;
@property (nonatomic, strong) UIToolbar *mediaToolbar;
@property (nonatomic, strong) id<WPMediaCollectionDataSource> privateDataSource;

@end

@implementation WPInputMediaPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    [self setupMediaPickerViewController];
}

- (void)setupMediaPickerViewController {
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.privateDataSource = [[WPPHAssetDataSource alloc] init];
    self.mediaPicker = [[WPMediaPickerViewController alloc] init];
    self.mediaPicker.dataSource = self.privateDataSource;


    [self addChildViewController:self.mediaPicker];
    self.mediaPicker.view.frame = self.view.bounds;
    self.mediaPicker.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mediaPicker.view];
    [self.mediaPicker didMoveToParentViewController:self];
    self.mediaPicker.collectionView.alwaysBounceVertical = NO;

    self.mediaToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.mediaToolbar.items = @[
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(mediaCanceled:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(mediaSelected:)]
                      ];
}

- (void)viewDidLayoutSubviews {
    CGFloat spacing = 1.0f;
    [super viewDidLayoutSubviews];
    CGFloat size = floorf((self.view.frame.size.height - spacing) / 2.0);
    self.mediaPicker.cameraPreviewSize = CGSizeMake(1.5*size, 1.5*size);
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(size, size);
    layout.minimumLineSpacing = spacing;
    layout.minimumInteritemSpacing = spacing;
    layout.sectionInset = UIEdgeInsetsMake(0, 5, 0, 10);

    self.mediaPicker.collectionView.collectionViewLayout = layout;

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
        [self.mediaPickerDelegate mediaPickerController:self.mediaPicker didFinishPickingAssets:[self.mediaPicker.selectedAssets copy]];
    }
    
}

- (void)mediaCanceled:(UIBarButtonItem *)sender {
    if ([self.mediaPickerDelegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.mediaPickerDelegate mediaPickerControllerDidCancel:self.mediaPicker];
    }
}


@end
