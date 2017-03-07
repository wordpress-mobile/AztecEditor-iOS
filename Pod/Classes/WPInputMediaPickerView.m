#import "WPInputMediaPickerView.h"
#import "WPPHAssetDataSource.h"

@interface WPInputMediaPickerView()

@property (nonatomic, strong) WPMediaPickerViewController *mediaPicker;
@property (nonatomic, strong) UIToolbar *mediaToolbar;

@end

@implementation WPInputMediaPickerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    WPMediaPickerViewController *vc = [[WPMediaPickerViewController alloc] init];
    self.mediaPicker = vc;
    vc.dataSource = [WPPHAssetDataSource sharedInstance];
    UICollectionView *collectionView = vc.collectionView;
    [collectionView setFrame:CGRectMake(0, 0, self.frame.size.width, 256)];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(126, 126);
    layout.minimumLineSpacing = 1.0f;
    layout.minimumInteritemSpacing = 1.0f;

    collectionView.collectionViewLayout = layout;
    collectionView.alwaysBounceVertical = NO;

    [self addSubview:self.mediaPicker.collectionView];

    self.mediaToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
    self.mediaToolbar.items = @[
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(mediaCanceled:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(mediaSelected:)]
                      ];
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
