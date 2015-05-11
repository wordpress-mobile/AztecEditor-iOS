#import "WPMediaCollectionViewController.h"
#import "WPMediaCollectionViewCell.h"
#import "WPMediaCaptureCollectionViewCell.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"
#import "WPALAssetDataSource.h"

@import MobileCoreServices;
@import AVFoundation;

@interface WPMediaCollectionViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, WPMediaGroupPickerViewControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSMutableArray *selectedAssetsGroup;
@property (nonatomic, strong) WPMediaCaptureCollectionViewCell *captureCell;
@property (nonatomic, strong) UIButton *titleButton;
@property (nonatomic, strong) UIPopoverController *popOverController;
@property (nonatomic, assign) BOOL ignoreMediaNotifications;
@property (nonatomic, strong) NSObject *changesObserver;

@end

@implementation WPMediaCollectionViewController

static CGFloat SpaceBetweenPhotos = 1.0f;
static CGFloat NumberOfPhotosForLine = 4;
static CGFloat SelectAnimationTime = 0.2;
static CGFloat MinimumCellSize = 105;
static NSString *const ArrowDown = @"\u25be";

- (instancetype)init
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self = [self initWithCollectionViewLayout:layout];
    if (self) {
        _layout = layout;
        _selectedAssets = [[NSMutableArray alloc] init];
        _selectedAssetsGroup = [[NSMutableArray alloc] init];
        _allowCaptureOfMedia = YES;
        _showMostRecentFirst = NO;
        _filter = WPMediaTypeAll;
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

    // Configure collection view behaviour
    self.clearsSelectionOnViewWillAppear = NO;
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
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

    // Configure collection view layout
    CGFloat width = roundf((self.view.frame.size.width - ((NumberOfPhotosForLine - 1) * SpaceBetweenPhotos)) / NumberOfPhotosForLine);
    width = MIN(width, MinimumCellSize);
    self.layout.itemSize = CGSizeMake(width, width);
    self.layout.minimumInteritemSpacing = SpaceBetweenPhotos;
    self.layout.minimumLineSpacing = SpaceBetweenPhotos;
    self.layout.sectionInset = UIEdgeInsetsMake(SpaceBetweenPhotos, 0, SpaceBetweenPhotos, 0);

    //setup navigation items
    self.titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.titleButton addTarget:self action:@selector(changeGroup:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = self.titleButton;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishPicker:)];

    self.ignoreMediaNotifications = NO;

    [self.dataSource setMediaTypeFilter:self.filter];
    __weak __typeof__(self) weakSelf = self;
    self.changesObserver = [self.dataSource registerChangeObserverBlock:^{
        [weakSelf refreshData];
    }];
    [self refreshData];
}

#pragma mark - Actions

+ (BOOL)isiOS8OrAbove
{
    NSComparisonResult result = [[[UIDevice currentDevice] systemVersion] compare:@"8.0.0" options:NSNumericSearch];

    return result == NSOrderedSame || result == NSOrderedDescending;
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
    return self.allowCaptureOfMedia && [self isMediaDeviceAvailable];
}

#pragma mark - UICollectionViewDataSource

- (void)refreshData
{
    [self.dataSource loadDataWithSuccess:^{
        [self refreshSelection];
        id<WPMediaGroup> mediaGroup = [self.dataSource selectedGroup];
        NSString *title = [NSString stringWithFormat:@"%@ %@", [mediaGroup name], ArrowDown];
        [self.titleButton setTitle:title forState:UIControlStateNormal];
        [self.titleButton sizeToFit];
        [self.collectionView reloadData];
        // Scroll to the correct position
        if ([self.dataSource numberOfAssets] > 0){
            NSInteger sectionToScroll = 0;
            NSInteger itemToScroll = self.showMostRecentFirst ? 0 :[self.dataSource numberOfAssets]-1;
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemToScroll inSection:sectionToScroll] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        }

    } failure:^(NSError *error) {
        NSLog(@"Error %@", error);
    }];
}

- (void)refreshSelection
{
    NSMutableSet *selectedAssetsSet = [NSMutableSet set];
    NSMutableSet *stillExistingSeletedAssets = [NSMutableSet set];
    id<WPMediaGroup> mediaGroup = [self.dataSource selectedGroup];
    NSString *currentGroupURL = [mediaGroup identifier];
    
    for (int i = 0; i < self.selectedAssets.count; i++) {
        id<WPMediaAsset> asset = (id<WPMediaAsset>)self.selectedAssets[i];
        [selectedAssetsSet addObject:[asset identifier]];
        
        NSString *assetGroupIdentifier = (NSString *)self.selectedAssetsGroup[i];
        if ( ![assetGroupIdentifier isEqual:currentGroupURL]) {
            [stillExistingSeletedAssets addObject:[asset identifier]];
        }
    }
    
    for (int i = 0; i < [self.dataSource numberOfAssets]; i++){
        id<WPMediaAsset> asset = (id<WPMediaAsset>)[self.dataSource mediaAtIndex:i];
        if ([selectedAssetsSet containsObject:[asset identifier]]) {
            [stillExistingSeletedAssets addObject:[asset identifier]];
        }
    }
    
    [selectedAssetsSet minusSet:stillExistingSeletedAssets];
    NSSet *missingAsset = [NSSet setWithSet:selectedAssetsSet];
    NSMutableArray *assetsToRemove = [NSMutableArray array];
    for (id<WPMediaAsset> selectedAsset in self.selectedAssets){
        if ([missingAsset containsObject:[selectedAsset identifier]]){
            [assetsToRemove addObject:selectedAsset];
        }
    }
    [self.selectedAssets removeObjectsInArray:assetsToRemove];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    int extraAssets = self.allowCaptureOfMedia ? 1 : 0;
    return [self.dataSource numberOfAssets] + extraAssets;
}

- (BOOL)isCaptureCellIndexPath:(NSIndexPath *)indexPath
{
    if (!self.allowCaptureOfMedia){
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
        if (self.allowCaptureOfMedia) {
            itemPosition++;
        }
    }
    id<WPMediaAsset> asset = [self.dataSource mediaAtIndex:itemPosition];
    return asset;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isCaptureCellIndexPath:indexPath] ) {
        self.captureCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPMediaCaptureCollectionViewCell class]) forIndexPath:indexPath];
        [self.captureCell startCapture];
        return self.captureCell;
    }
    
    id<WPMediaAsset> asset = [self assetForPosition:indexPath];
    WPMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class]) forIndexPath:indexPath];

    // Configure the cell
    cell.image = [asset thumbnailWithSize:CGSizeZero];
    NSUInteger position = [self positionOfAssetInSelection:asset];
    if (position != NSNotFound) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [cell setPosition:position + 1];
        cell.selected = YES;
    } else {
        [cell setPosition:NSNotFound];
        cell.selected = NO;
    }

    if ([asset mediaType] == WPMediaTypeVideo) {
        NSNumber *duration = [asset duration];
        NSString *caption = [self stringFromTimeInterval:[duration doubleValue]];
        [cell setCaption:caption];
    } else {
        [cell setCaption:@""];
    }

    return cell;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger roundedHours = floor(timeInterval / 3600);
    NSInteger roundedMinutes = floor((timeInterval - (3600 * roundedHours)) / 60);
    NSInteger roundedSeconds = round(timeInterval - (roundedHours * 60 * 60) - (roundedMinutes * 60));

    if (roundedHours > 0)
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)roundedHours, (long)roundedMinutes, (long)roundedSeconds];

    else
        return [NSString stringWithFormat:@"%ld:%02ld", (long)roundedMinutes, (long)roundedSeconds];
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
    [self.selectedAssets addObject:asset];
    [self.selectedAssetsGroup addObject:[[self.dataSource selectedGroup] identifier]];
    
    WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell setPosition:self.selectedAssets.count];
    [self animateCellSelection:cell completion:^{
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }];

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
        [self.selectedAssetsGroup removeObjectAtIndex:deselectPosition];
    }

    WPMediaCollectionViewCell *cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self animateCellSelection:cell completion:^{
        [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForSelectedItems];
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
    imagePickerController.mediaTypes =
        [UIImagePickerController availableMediaTypesForSourceType:
                                     UIImagePickerControllerSourceTypeCamera];
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
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Media Capture", @"Title for alert when access to media capture is not granted")
                                                    message:NSLocalizedString(@"This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", @"")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil] show];
                    return;
                }
                [self showMediaCaptureViewController];
            });
        }];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Media Capture", @"Title for alert when access to media capture is not granted")
                                    message:NSLocalizedString(@"This app needs permission to access the Camera to capture new media, please change the privacy settings if you wish to allow this.", @"")
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    });
}

- (void)processMediaCaptured:(NSDictionary *)info
{
    self.ignoreMediaNotifications = YES;
    WPMediaAddedBlock completionBlock = ^(id<WPMediaAsset> media, NSError *error) {
        if (error){
            return;
        }
        [self addMedia:media];
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

- (void)addMedia:(id<WPMediaAsset>)asset
{
    BOOL willBeSelected = YES;
    id<WPMediaGroup> mediaGroup = [self.dataSource selectedGroup];
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        if ([self.picker.delegate mediaPickerController:self.picker shouldSelectAsset:asset]) {
            [self.selectedAssets addObject:asset];
            [self.selectedAssetsGroup addObject:[mediaGroup identifier]];
        } else {
            willBeSelected = NO;
        }
    } else {
        [self.selectedAssets addObject:asset];
        [self.selectedAssetsGroup addObject:[mediaGroup identifier]];
    }

    NSUInteger insertPosition = [self showMostRecentFirst] ? 1 : [self.dataSource numberOfAssets]-1;

    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:insertPosition inSection:0]]];

    if ( ![self showMostRecentFirst] ){
        NSUInteger reloadPosition = [self.dataSource numberOfAssets];
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:reloadPosition inSection:0]]];
    } else {
        NSUInteger reloadPosition = MIN([self.dataSource numberOfAssets], 2);
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:reloadPosition inSection:0]]];
    }
    self.ignoreMediaNotifications = NO;
    
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
        && ![[self class] isiOS8OrAbove]) {
        [self.popOverController dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [self.dataSource setSelectedGroup:group];
    [self refreshData];
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
@end
