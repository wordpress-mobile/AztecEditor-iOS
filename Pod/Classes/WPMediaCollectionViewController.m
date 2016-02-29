#import "WPMediaCollectionViewController.h"
#import "WPMediaCollectionViewCell.h"
#import "WPMediaCapturePreviewCollectionView.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"

@import MobileCoreServices;
@import AVFoundation;

@interface WPMediaCollectionViewController ()
<
 UIImagePickerControllerDelegate,
 UINavigationControllerDelegate,
 WPMediaGroupPickerViewControllerDelegate,
 UIPopoverPresentationControllerDelegate,
 UICollectionViewDelegateFlowLayout
>

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) WPMediaCapturePreviewCollectionView *captureCell;
@property (nonatomic, strong) UIButton *titleButton;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSObject *changesObserver;
@property (nonatomic, strong) NSIndexPath *firstVisibleCell;
@property (nonatomic, assign) BOOL refreshGroupFirstTime;

@end

@implementation WPMediaCollectionViewController

static CGFloat SelectAnimationTime = 0.2;
static NSString *const ArrowDown = @"\u25be";
static CGSize CameraPreviewSize =  {88.0, 88.0};

- (instancetype)init
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self = [self initWithCollectionViewLayout:layout];
    if (self) {
        _layout = layout;
        _selectedAssets = [[NSMutableArray alloc] init];
        _allowCaptureOfMedia = YES;
        _showMostRecentFirst = NO;
        _filter = WPMediaTypeVideoOrImage;
        _refreshGroupFirstTime = YES;
    }
    return self;
}

- (void)dealloc
{
    [_dataSource unregisterChangeObserver:_changesObserver];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    // Configure collection view behaviour
    self.clearsSelectionOnViewWillAppear = NO;
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = self.allowMultipleSelection;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.alwaysBounceVertical = YES;

    // Register cell classes
    [self.collectionView registerClass:[WPMediaCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class])];
    [self.collectionView registerClass:[WPMediaCapturePreviewCollectionView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class])];
    [self.collectionView registerClass:[WPMediaCapturePreviewCollectionView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class])];
    [self setupLayout];

    //setup navigation items
    self.titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.titleButton addTarget:self action:@selector(changeGroup:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = self.titleButton;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishPicker:)];

    //setup data
    [self.dataSource setMediaTypeFilter:self.filter];
    __weak __typeof__(self) weakSelf = self;
    self.changesObserver = [self.dataSource registerChangeObserverBlock:^{
        [weakSelf refreshData];
    }];
    [self refreshData];
}

- (void)setupLayout
{
    CGFloat minWidth = MIN (self.view.frame.size.width, self.view.frame.size.height);
    // Configure collection view layout
    CGFloat numberOfPhotosForLine = 4;
    CGFloat spaceBetweenPhotos = 1.0f;
    CGFloat leftRightInset = 0;
    CGFloat topBottomInset = 5;
    
    CGFloat width = floorf((minWidth - (((numberOfPhotosForLine -1) * spaceBetweenPhotos)) + (2*leftRightInset)) / numberOfPhotosForLine);
    
    self.layout.itemSize = CGSizeMake(width, width);
    self.layout.minimumInteritemSpacing = spaceBetweenPhotos;
    self.layout.minimumLineSpacing = spaceBetweenPhotos;
    self.layout.sectionInset = UIEdgeInsetsMake(topBottomInset, leftRightInset, topBottomInset, leftRightInset);

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self setupLayout];
}

#pragma mark - Actions

- (void)pullToRefresh:(id)sender
{
    [self refreshData];
}

- (void)changeGroup:(UIButton *)sender
{
    WPMediaGroupPickerViewController *groupViewController = [[WPMediaGroupPickerViewController alloc] init];
    groupViewController.delegate = self;
    groupViewController.dataSource = self.dataSource;

    groupViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = groupViewController.popoverPresentationController;
    ppc.delegate = self;
    ppc.sourceView = sender;
    ppc.sourceRect = [sender bounds];
    [self presentViewController:groupViewController animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}

- (void)cancelPicker:(UIBarButtonItem *)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
        [self.picker.delegate mediaPickerControllerDidCancel:self.picker];
    }
}

- (void)finishPicker:(UIBarButtonItem *)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
        [self.picker.delegate mediaPickerController:self.picker didFinishPickingAssets:[self.selectedAssets copy]];
    }
}

- (WPMediaPickerViewController *)picker
{
    return (WPMediaPickerViewController *)self.navigationController.parentViewController;
}

- (BOOL)isShowingCaptureCell
{
    return self.allowCaptureOfMedia && [self isMediaDeviceAvailable] && !self.refreshGroupFirstTime;
}

- (void)refreshTitle {
    id<WPMediaGroup> mediaGroup = [self.dataSource selectedGroup];
    if (!mediaGroup) {
        // mediaGroup can be nil in some cases. For instance if the
        // user denied access to the device's Photos.
        self.titleButton.hidden = YES;
        return;
    } else {
        self.titleButton.hidden = NO;
    }
    NSString *title = [NSString stringWithFormat:@"%@ %@", [mediaGroup name], ArrowDown];
    [self.titleButton setTitle:title forState:UIControlStateNormal];
    [self.titleButton sizeToFit];
}

#pragma mark - UICollectionViewDataSource

- (void)refreshData
{
    if (self.refreshGroupFirstTime) {
        if (![self.refreshControl isRefreshing]) {
            [self.collectionView setContentOffset:CGPointMake(0, - [[self topLayoutGuide] length]) animated:NO];
            [self.collectionView setContentOffset:CGPointMake(0, - [[self topLayoutGuide] length] - (self.refreshControl.frame.size.height)) animated:YES];
            [self.refreshControl beginRefreshing];
        }
        // NOTE: Sergio Estevao (2015-11-19)
        // Clean all assets and refresh collection view when the group was changed
        // This avoid to see data from previous group while the new one is loading.
        [self.collectionView reloadData];
    }
    self.collectionView.allowsSelection = NO;
    self.collectionView.scrollEnabled = NO;
    __weak __typeof__(self) weakSelf = self;
    [self.dataSource loadDataWithSuccess:^{
        __typeof__(self) strongSelf = weakSelf;        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [strongSelf refreshSelection];
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf refreshTitle];
                strongSelf.collectionView.allowsSelection = YES;
                strongSelf.collectionView.scrollEnabled = YES;
                [strongSelf.collectionView reloadData];
                [strongSelf.refreshControl endRefreshing];
                // Scroll to the correct position
                if (strongSelf.refreshGroupFirstTime && [strongSelf.dataSource numberOfAssets] > 0){
                    strongSelf.refreshGroupFirstTime = NO;
                    NSInteger sectionToScroll = 0;
                    NSInteger itemToScroll = strongSelf.showMostRecentFirst ? 0 :[strongSelf.dataSource numberOfAssets]-1;
                    [strongSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemToScroll inSection:sectionToScroll]
                                                      atScrollPosition:UICollectionViewScrollPositionCenteredVertically
                                                              animated:NO];
                }
            });
 
        });
    } failure:^(NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf showError:error];
        });
    }];
}

- (void)showError:(NSError *)error {
    [self refreshTitle];
    [self.refreshControl endRefreshing];
    self.collectionView.allowsSelection = YES;
    self.collectionView.scrollEnabled = YES;
    [self.collectionView reloadData];
    NSString *title = NSLocalizedString(@"Media Library", @"Title for alert when a generic error happened when loading media");
    NSString *message = NSLocalizedString(@"There was a problem when trying to access your media. Please try again later.",  @"Explaining to the user there was an generic error accesing media.");
    NSString *cancelText = NSLocalizedString(@"OK", "");
    NSString *otherButtonTitle = nil;
    if (error.domain == WPMediaPickerErrorDomain &&
        error.code == WPMediaErrorCodePermissionsFailed) {
        otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
    }
    title = NSLocalizedString(@"Media Library", @"Title for alert when access to the media library is not granted by the user");
    message = NSLocalizedString(@"This app needs permission to access your device media library in order to add photos and/or video to your posts. Please change the privacy settings if you wish to allow this.",  @"Explaining to the user why the app needs access to the device media library.");
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:cancelText style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if ([self.picker.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
            [self.picker.delegate mediaPickerControllerDidCancel:self.picker];
        }
    }];
    [alertController addAction:okAction];
    
    if (otherButtonTitle) {
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:settingsURL];
        }];
        [alertController addAction:otherAction];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)refreshSelection
{
    NSArray *selectedAssets = [NSArray arrayWithArray:self.selectedAssets];
    NSMutableArray *stillExistingSeletedAssets = [NSMutableArray array];
    for (id<WPMediaAsset> asset in selectedAssets) {
        NSString *assetIdentifier = [asset identifier];
        if ([self.dataSource mediaWithIdentifier:assetIdentifier]) {
            [stillExistingSeletedAssets addObject:asset];
        }
    }
    self.selectedAssets = stillExistingSeletedAssets;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource numberOfAssets];
}

- (id<WPMediaAsset>)assetForPosition:(NSIndexPath *)indexPath
{
    NSInteger itemPosition = indexPath.item;
    NSInteger count = [self.dataSource numberOfAssets];
    if (self.showMostRecentFirst){
        itemPosition = count - 1 - itemPosition;
    }
    if (itemPosition >= count || itemPosition < 0) {
        return nil;
    }
    id<WPMediaAsset> asset = [self.dataSource mediaAtIndex:itemPosition];
    return asset;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    WPMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class]) forIndexPath:indexPath];

    // Configure the cell
    cell.asset = asset;
    NSUInteger position = [self positionOfAssetInSelection:asset];
    if (position != NSNotFound) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        if (self.allowMultipleSelection) {
            [cell setPosition:position + 1];
        } else {
            [cell setPosition:NSNotFound];
        }
        cell.selected = YES;
    } else {
        [cell setPosition:NSNotFound];
        cell.selected = NO;
    }

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    if ( [self isShowingCaptureCell] && self.showMostRecentFirst)
    {
        return CameraPreviewSize;
    }
    return CGSizeZero;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section
{
    if ( [self isShowingCaptureCell] && !self.showMostRecentFirst)
    {
        return CameraPreviewSize;
    }
    return CGSizeZero;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    if ((kind == UICollectionElementKindSectionHeader && self.showMostRecentFirst) ||
       (kind == UICollectionElementKindSectionFooter && !self.showMostRecentFirst))
    {
        self.captureCell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([WPMediaCapturePreviewCollectionView class]) forIndexPath:indexPath];
        if (self.captureCell.gestureRecognizers == nil) {
            UIGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showCapture)];
            [self.captureCell addGestureRecognizer:tapGestureRecognizer];
        }
        [self.captureCell startCapture];
        return self.captureCell;
    }

    return nil;
}

- (void)showCapture {
    [self.captureCell stopCaptureOnCompletion:^{
        [self captureMedia];
    }];
    return;
}

- (NSUInteger)positionOfAssetInSelection:(id<WPMediaAsset>)asset
{
    NSUInteger position = [self.selectedAssets indexOfObjectPassingTest:^BOOL(id<WPMediaAsset> loopAsset, NSUInteger idx, BOOL *stop) {
        BOOL found =  [[asset identifier]  isEqual:[loopAsset identifier]];
        return found;
    }];
    return position;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        return [self.picker.delegate mediaPickerController:self.picker shouldSelectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if (!self.allowMultipleSelection) {
        [self.selectedAssets removeAllObjects];
    }
    [self.selectedAssets addObject:asset];
    
    WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (self.allowMultipleSelection) {
        [cell setPosition:self.selectedAssets.count];
    } else {
        [cell setPosition:NSNotFound];
    }
    [self animateCellSelection:cell completion:nil];

    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.picker.delegate mediaPickerController:self.picker didSelectAsset:asset];
    }
    if (!self.allowMultipleSelection) {
        if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
            [self.picker.delegate mediaPickerController:self.picker didFinishPickingAssets:[self.selectedAssets copy]];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldDeselectAsset:)]) {
        return [self.picker.delegate mediaPickerController:self.picker shouldDeselectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{

    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    NSUInteger deselectPosition = [self positionOfAssetInSelection:asset];
    if (deselectPosition != NSNotFound) {
        [self.selectedAssets removeObjectAtIndex:deselectPosition];
    }

    WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self animateCellSelection:cell completion:^{
        for (NSIndexPath *selectedIndexPath in self.collectionView.indexPathsForSelectedItems){
            WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:selectedIndexPath];
            id<WPMediaAsset> asset = [self assetForPosition:selectedIndexPath];
            NSUInteger position = [self positionOfAssetInSelection:asset];
            if (position != NSNotFound) {
                if (self.allowMultipleSelection) {
                    [cell setPosition:position + 1];
                } else {
                    [cell setPosition:NSNotFound];
                }
            }
        }
    }];

    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didDeselectAsset:)]) {
        [self.picker.delegate mediaPickerController:self.picker didDeselectAsset:asset];
    }
}

- (void)animateCellSelection:(UIView *)cell completion:(void (^)())completionBlock
{
    [UIView animateKeyframesWithDuration:SelectAnimationTime delay:0 options:UIViewKeyframeAnimationOptionCalculationModePaced animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:SelectAnimationTime/2 animations:^{
            cell.frame = CGRectInset(cell.frame, 1, 1);
        }];
        [UIView addKeyframeWithRelativeStartTime:SelectAnimationTime/2 relativeDuration:SelectAnimationTime/2 animations:^{
            cell.frame = CGRectInset(cell.frame, -1, -1);
        }];
    } completion:^(BOOL finished) {
        if(completionBlock){
            completionBlock();
        }
    }];
}

- (void)animateCaptureCellSelection:(UIView *)cell completion:(void (^)())completionBlock
{
    [UIView animateKeyframesWithDuration:0.5 delay:0 options:UIViewKeyframeAnimationOptionCalculationModePaced animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:1 animations:^{
            CGRect frame = self.view.frame;
            frame.origin.x += self.collectionView.contentOffset.x;
            frame.origin.y += self.collectionView.contentOffset.y;
            cell.frame = frame;
        }];
    } completion:^(BOOL finished) {
        if(completionBlock){
            completionBlock();
        }
    }];
}

#pragma mark - Media Capture

- (BOOL)isMediaDeviceAvailable
{
    // check if device is capable of capturing photos all together
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (void)showMediaCaptureViewController
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    NSMutableSet *mediaTypes = [NSMutableSet setWithArray:[UIImagePickerController availableMediaTypesForSourceType:
                           UIImagePickerControllerSourceTypeCamera]];
    switch (self.filter) {
        case(WPMediaTypeImage): {
            [mediaTypes intersectSet:[NSSet setWithArray:@[(__bridge NSString *)kUTTypeImage]]];
        } break;
        case(WPMediaTypeVideo): {
            [mediaTypes intersectSet:[NSSet setWithArray:@[(__bridge NSString *)kUTTypeMovie]]];
        } break;
        default: {
            //Don't intersect at all
        }
    }
    imagePickerController.mediaTypes = [mediaTypes allObjects];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:imagePickerController animated:YES completion:^{

    }];
}

- (void)captureMedia
{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authorizationStatus == AVAuthorizationStatusAuthorized) {
        [self showMediaCaptureViewController];
        return;
    }

    if (authorizationStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted)
                {
                    [self showAlertAboutMediaCapturePermission];
                    return;
                }
                [self showMediaCaptureViewController];
            });
        }];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertAboutMediaCapturePermission];
    });
}

- (void)showAlertAboutMediaCapturePermission
{
    NSString *title = NSLocalizedString(@"Media Capture", @"Title for alert when access to media capture is not granted");
    NSString *message =NSLocalizedString(@"This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", @"");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", "Confirmation of action") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:okAction];
    
    NSString *otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }];
    [alertController addAction:otherAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)processMediaCaptured:(NSDictionary *)info
{
    WPMediaAddedBlock completionBlock = ^(id<WPMediaAsset> media, NSError *error) {
        if (error || !media) {
            NSLog(@"Adding media failed: %@", [error localizedDescription]);
            return;
        }
        [self addMedia:media animated:YES];
    };
    if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeImage]) {
        UIImage *image = (UIImage *)info[UIImagePickerControllerOriginalImage];
        [self.dataSource addImage:image
                         metadata:info[UIImagePickerControllerMediaMetadata]
                  completionBlock:completionBlock];
    } else if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeMovie]) {
        [self.dataSource addVideoFromURL:info[UIImagePickerControllerMediaURL] completionBlock:completionBlock];
    }
}

- (void)addMedia:(id<WPMediaAsset>)asset animated:(BOOL)animated
{
    BOOL willBeSelected = YES;
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        if ([self.picker.delegate mediaPickerController:self.picker shouldSelectAsset:asset]) {
            [self.selectedAssets addObject:asset];
        } else {
            willBeSelected = NO;
        }
    } else {
        [self.selectedAssets addObject:asset];
    }
    
    if (!willBeSelected) {
        return;
    }
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]) {
        [self.picker.delegate mediaPickerController:self.picker didSelectAsset:asset];
    }
    if (!self.allowMultipleSelection) {
        if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]) {
            [self.picker.delegate mediaPickerController:self.picker didFinishPickingAssets:[self.selectedAssets copy]];
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self processMediaCaptured:info];
        if (self.showMostRecentFirst){
            [self.captureCell startCapture];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self.captureCell startCapture];
    }];
}

#pragma mark - WPMediaGroupViewControllerDelegate

- (void)mediaGroupPickerViewController:(WPMediaGroupPickerViewController *)picker didPickGroup:(id<WPMediaGroup>)group
{
    if (group == [self.dataSource selectedGroup]){
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    self.refreshGroupFirstTime = YES;
    [self.dataSource setSelectedGroup:group];
    [self refreshTitle];
    [self dismissViewControllerAnimated:YES completion:^{
        [self refreshData];
    }];
}

- (void)mediaGroupPickerViewControllerDidCancel:(WPMediaGroupPickerViewController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
