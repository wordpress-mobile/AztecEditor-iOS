#import "WPMediaCollectionViewController.h"
#import "WPMediaCollectionViewCell.h"
#import "WPMediaCaptureCollectionViewCell.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"

@import MobileCoreServices;
@import AVFoundation;

typedef NS_ENUM(NSUInteger, WPMediaCollectionAlert){
    WPMediaCollectionAlertMediaLibraryPermissionsNeeded,
    WPMediaCollectionAlertMediaCapturePermissionsNeeded,
    WPMediaCollectionAlertOtherError
};

@interface WPMediaCollectionViewController ()
<
 UIImagePickerControllerDelegate,
 UINavigationControllerDelegate,
 WPMediaGroupPickerViewControllerDelegate,
 UIPopoverPresentationControllerDelegate,
 UIAlertViewDelegate
>

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) WPMediaCaptureCollectionViewCell *captureCell;
@property (nonatomic, strong) UIButton *titleButton;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIPopoverController *popOverController;
@property (nonatomic, assign) NSTimeInterval ignoreMediaTimestamp;
@property (nonatomic, strong) NSObject *changesObserver;
@property (nonatomic, strong) NSIndexPath *firstVisibleCell;
@property (nonatomic, assign) BOOL refreshGroupFirstTime;

@end

@implementation WPMediaCollectionViewController

static CGFloat SelectAnimationTime = 0.2;
static NSString *const ArrowDown = @"\u25be";
static NSTimeInterval TimeToIgnoreNotificationAfterAddition = 2;

- (instancetype)init
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self = [self initWithCollectionViewLayout:layout];
    if (self) {
        _layout = layout;
        _selectedAssets = [[NSMutableArray alloc] init];
        _allowCaptureOfMedia = YES;
        _showMostRecentFirst = NO;
        _filter = WPMediaTypeAll;
        _refreshGroupFirstTime = YES;
        _ignoreMediaTimestamp = 0;
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
    // HACK: Fix for iOS 7 not respecting the appeareance background color
    if (![[self class] isiOS8OrAbove]) {
        UIColor * appearanceColor = [[UICollectionView appearanceWhenContainedIn:[WPMediaCollectionViewController class],nil] backgroundColor];
        if (!appearanceColor){
            appearanceColor = [[UICollectionView appearance] backgroundColor];
        }
        self.collectionView.backgroundColor = appearanceColor;
    }
    // Register cell classes
    [self.collectionView registerClass:[WPMediaCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class])];
    [self.collectionView registerClass:[WPMediaCaptureCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([WPMediaCaptureCollectionViewCell class])];

    [self setupLayoutForOrientation:self.interfaceOrientation];

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
        if (([NSDate timeIntervalSinceReferenceDate] - weakSelf.ignoreMediaTimestamp) > TimeToIgnoreNotificationAfterAddition){
            [weakSelf refreshData];
        }
    }];
    [self refreshData];
}

- (void)setupLayoutForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    CGFloat minWidth = MIN (self.view.frame.size.width, self.view.frame.size.height);
    // Configure collection view layout
    CGFloat numberOfPhotosForLine = 4;
    CGFloat spaceBetweenPhotos = 1.0f;
    CGFloat leftRightInset = 0;
    CGFloat topBottomInset = 5;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        numberOfPhotosForLine = 5;
    }
    
    CGFloat width = floorf((minWidth - (((numberOfPhotosForLine -1) * spaceBetweenPhotos)) + (2*leftRightInset)) / numberOfPhotosForLine);
    
    self.layout.itemSize = CGSizeMake(width, width);
    self.layout.minimumInteritemSpacing = spaceBetweenPhotos;
    self.layout.minimumLineSpacing = spaceBetweenPhotos;
    self.layout.sectionInset = UIEdgeInsetsMake(topBottomInset, leftRightInset, topBottomInset, leftRightInset);

}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.firstVisibleCell = [self.collectionView.indexPathsForVisibleItems firstObject];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (!self.firstVisibleCell){
        return;
    }
    [self.collectionView scrollToItemAtIndexPath:self.firstVisibleCell
                                atScrollPosition:UICollectionViewScrollPositionLeft|UICollectionViewScrollPositionTop
                                        animated:NO];
}

#pragma mark - Actions

+ (BOOL)isiOS8OrAbove
{
    NSComparisonResult result = [[[UIDevice currentDevice] systemVersion] compare:@"8.0.0" options:NSNumericSearch];

    return result == NSOrderedSame || result == NSOrderedDescending;
}

- (void)pullToRefresh:(id)sender
{
    [self refreshData];
}

- (void)changeGroup:(UIButton *)sender
{
    WPMediaGroupPickerViewController *groupViewController = [[WPMediaGroupPickerViewController alloc] init];
    groupViewController.delegate = self;
    groupViewController.dataSource = self.dataSource;

    if ([[self class] isiOS8OrAbove]) {
        groupViewController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *ppc = groupViewController.popoverPresentationController;
        ppc.delegate = self;
        ppc.sourceView = sender;
        ppc.sourceRect = [sender bounds];
        [self presentViewController:groupViewController animated:YES completion:nil];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.popOverController = [[UIPopoverController alloc] initWithContentViewController:groupViewController];
        [self.popOverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

    } else {
        UINavigationController *groupNavigationController = [[UINavigationController alloc] initWithRootViewController:groupViewController];
        [self presentViewController:groupNavigationController animated:YES completion:nil];
    }
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
        strongSelf.refreshGroupFirstTime = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [strongSelf refreshSelection];
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf refreshTitle];
                strongSelf.collectionView.allowsSelection = YES;
                strongSelf.collectionView.scrollEnabled = YES;
                [strongSelf.collectionView reloadData];
                [strongSelf.refreshControl endRefreshing];
                // Scroll to the correct position
                if ([strongSelf.dataSource numberOfAssets] > 0){
                    NSInteger sectionToScroll = 0;
                    NSInteger showingLiveCellAdjustment = [self isShowingCaptureCell] ? 0:1;
                    NSInteger itemToScroll = strongSelf.showMostRecentFirst ? 0 :[strongSelf.dataSource numberOfAssets]-showingLiveCellAdjustment;
                    [strongSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemToScroll inSection:sectionToScroll]
                                                      atScrollPosition:UICollectionViewScrollPositionBottom
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
    NSInteger tag =  WPMediaCollectionAlertOtherError;
    if (error.domain == WPMediaPickerErrorDomain &&
        error.code == WPMediaErrorCodePermissionsFailed) {
        if ([[self class] isiOS8OrAbove]) {
            otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
        }
        title = NSLocalizedString(@"Media Library", @"Title for alert when access to the media library is not granted by the user");
        message = NSLocalizedString(@"This app needs permission to access your device media library in order to add photos and/or video to your posts. Please change the privacy settings if you wish to allow this.",  @"Explaining to the user why the app needs access to the device media library.");
        tag =  WPMediaCollectionAlertMediaLibraryPermissionsNeeded;
    }
    if ([[self class] isiOS8OrAbove]) {
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
            [self presentViewController:alertController animated:YES completion:nil];
        }
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:cancelText
                                                  otherButtonTitles:otherButtonTitle, nil];
        alertView.tag = tag;
        [alertView show];
    }
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
    int extraAssets = [self isShowingCaptureCell] ? 1 : 0;
    return [self.dataSource numberOfAssets] + extraAssets;
}

- (BOOL)isCaptureCellIndexPath:(NSIndexPath *)indexPath
{
    if (![self isShowingCaptureCell]){
        return NO;
    }
    NSInteger positionOfCapture = self.showMostRecentFirst ? 0 : [self.dataSource numberOfAssets];
    return positionOfCapture == indexPath.item;
}

- (id<WPMediaAsset>)assetForPosition:(NSIndexPath *)indexPath
{
    NSInteger itemPosition = indexPath.item;
    NSInteger count = [self.dataSource numberOfAssets];
    if (self.showMostRecentFirst){
        itemPosition = count - 1 - itemPosition;
        if ([self isShowingCaptureCell]) {
            itemPosition++;
        }
    }
    if (itemPosition >= count || itemPosition < 0) {
        return nil;
    }
    id<WPMediaAsset> asset = [self.dataSource mediaAtIndex:itemPosition];
    return asset;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isCaptureCellIndexPath:indexPath]) {
        self.captureCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPMediaCaptureCollectionViewCell class]) forIndexPath:indexPath];
        [self.captureCell startCapture];
        return self.captureCell;
    }
    
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
    // you can always select the capture
    if ([self isCaptureCellIndexPath:indexPath]) {
        return YES;
    }
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        return [self.picker.delegate mediaPickerController:self.picker shouldSelectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isCaptureCellIndexPath:indexPath]) {
        [self.captureCell stopCaptureOnCompletion:^{
            [self captureMedia];
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }];
        return;
    }
    
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
    // you can always deselect the capture
    if ([self isCaptureCellIndexPath:indexPath]) {
        return YES;
    }
    
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldDeselectAsset:)]) {
        return [self.picker.delegate mediaPickerController:self.picker shouldDeselectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // check if deselected the capture item
    if ([self isCaptureCellIndexPath:indexPath]) {
        return;
    }

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
    NSString *otherButtonTitle = nil;
    if ([[self class] isiOS8OrAbove]) {
        otherButtonTitle = NSLocalizedString(@"Open Settings", @"Go to the settings app");
    }

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Media Capture", @"Title for alert when access to media capture is not granted")
                                message:NSLocalizedString(@"This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", @"")
                               delegate:self
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:otherButtonTitle, nil];
    alertView.tag = WPMediaCollectionAlertMediaCapturePermissionsNeeded;
    [alertView show];
}

- (void)processMediaCaptured:(NSDictionary *)info
{
    NSInteger mediaItemsBefore = [self.dataSource numberOfAssets];
    self.ignoreMediaTimestamp = [NSDate timeIntervalSinceReferenceDate];
    WPMediaAddedBlock completionBlock = ^(id<WPMediaAsset> media, NSError *error) {
        if (error || !media) {
            NSLog(@"Adding media failed: %@", [error localizedDescription]);
            return;
        }
        NSInteger mediaItemsAfter = [self.dataSource numberOfAssets];
        [self addMedia:media animated:mediaItemsAfter != mediaItemsBefore];
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
    NSUInteger insertPosition = [self showMostRecentFirst] ? 1 : [self.dataSource numberOfAssets]-1;
    if (animated){
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:insertPosition inSection:0]]];

        if ( ![self showMostRecentFirst] ){
            NSUInteger reloadPosition = [self.dataSource numberOfAssets];
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:reloadPosition inSection:0]]];
        } else {
            NSUInteger reloadPosition = MIN([self.dataSource numberOfAssets], 2);
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:reloadPosition inSection:0]]];
        }
        if (!self.showMostRecentFirst) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self.dataSource numberOfAssets] inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        }
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
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
            && ![[self class] isiOS8OrAbove]) {
            [self.popOverController dismissPopoverAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        return;
    }
    self.refreshGroupFirstTime = YES;
    [self.dataSource setSelectedGroup:group];
    [self refreshTitle];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
        && ![[self class] isiOS8OrAbove]) {
        [self.popOverController dismissPopoverAnimated:YES];
        [self refreshData];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [self refreshData];
        }];
    }

}

- (void)mediaGroupPickerViewControllerDidCancel:(WPMediaGroupPickerViewController *)picker
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
        && ![[self class] isiOS8OrAbove]) {
        [self.popOverController dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case WPMediaCollectionAlertMediaLibraryPermissionsNeeded:
        {
            if (alertView.cancelButtonIndex == buttonIndex){
                if ([self.picker.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
                    [self.picker.delegate mediaPickerControllerDidCancel:self.picker];
                }
            } else if (alertView.firstOtherButtonIndex == buttonIndex) {
                if ([self.picker.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]) {
                    [self.picker.delegate mediaPickerControllerDidCancel:self.picker];
                }
                NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:settingsURL];
            }
        } break;
        case WPMediaCollectionAlertMediaCapturePermissionsNeeded:
        {
            if (alertView.firstOtherButtonIndex == buttonIndex) {
                NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:settingsURL];
            }
        } break;

            
        default:
            break;
    }
}
@end
