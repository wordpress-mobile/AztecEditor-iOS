#import "WPMediaCollectionViewController.h"
#import "WPMediaCollectionViewCell.h"
#import "WPMediaCaptureCollectionViewCell.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"

@import AssetsLibrary;
@import MobileCoreServices;
@import AVFoundation;

@interface WPMediaCollectionViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, WPMediaGroupPickerViewControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSMutableArray *selectedAssetsGroup;
@property (nonatomic, strong) ALAsset *liveAsset;
@property (nonatomic, strong) WPMediaCaptureCollectionViewCell *captureCell;
@property (nonatomic, strong) UIButton *titleButton;
@property (nonatomic, strong) UIPopoverController *popOverController;
@property (nonatomic, assign) BOOL ignoreMediaNotifications;

@end

@implementation WPMediaCollectionViewController

static CGFloat SpaceBetweenPhotos = 1.0f;
static CGFloat NumberOfPhotosForLine = 4;
static CGFloat SelectAnimationTime = 0.2;
static CGFloat MinimumCellSize = 105;
static NSString *const ArrowDown = @"\u25be";

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self = [self initWithCollectionViewLayout:layout];
    if (self) {
        _layout = layout;
        _assets = [[NSMutableArray alloc] init];
        _selectedAssets = [[NSMutableArray alloc] init];
        _selectedAssetsGroup = [[NSMutableArray alloc] init];
        _allowCaptureOfMedia = YES;
        _showMostRecentFirst = NO;
        _liveAsset = [[ALAsset alloc] init];
        _assetsFilter = [ALAssetsFilter allAssets];
    }
    return self;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibraryNotification:) name:ALAssetsLibraryChangedNotification object:self.assetsLibrary];
    
    [self loadData];
}

- (void)handleLibraryNotification:(NSNotification *)note
{
    NSURL *currentGroupID = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
    NSSet *groupsChanged = note.userInfo[ALAssetLibraryUpdatedAssetGroupsKey];
    NSSet *assetsChanged = note.userInfo[ALAssetLibraryUpdatedAssetsKey];
    if (  groupsChanged && [groupsChanged containsObject:currentGroupID]
        && assetsChanged.count > 0
        && !self.ignoreMediaNotifications) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadData];
        });
    }
}

#pragma mark - Properties

- (ALAssetsLibrary *)assetsLibrary
{
    static dispatch_once_t onceToken;
    static ALAssetsLibrary *_assetsLibrary;
    dispatch_once(&onceToken, ^{
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    });
    return _assetsLibrary;
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
    groupViewController.assetsLibrary = self.assetsLibrary;
    groupViewController.selectedGroup = self.assetsGroup;

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

- (void)loadData
{
    [self.assets removeAllObjects];
    
    NSMutableSet *selectedAssetsSet = [NSMutableSet set];
    NSMutableSet *stillExistingSeletedAssets = [NSMutableSet set];
    NSURL *currentGroupURL = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
    for (int i =0; i < self.selectedAssets.count; i++) {
        ALAsset *asset = (ALAsset *)self.selectedAssets[i];
        NSURL *assetURL = (NSURL *)[asset valueForProperty:ALAssetPropertyAssetURL];
        [selectedAssetsSet addObject:assetURL];
        
        ALAssetsGroup *assetGroup = (ALAssetsGroup *)self.selectedAssetsGroup[i];
        NSURL *assetGroupURL = [assetGroup valueForProperty:ALAssetsGroupPropertyURL];
        if ( ![assetGroupURL isEqual:currentGroupURL]) {
            [stillExistingSeletedAssets addObject:assetURL];
        }
    }
    
    if (!self.assetsGroup) {
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if(!group){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadData];
                });
                return;
            }
            self.assetsGroup = group;
        } failureBlock:^(NSError *error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        }];
        return;
    }

    NSString *title = [NSString stringWithFormat:@"%@ %@", (NSString *)[self.assetsGroup valueForProperty:ALAssetsGroupPropertyName], ArrowDown];
    [self.titleButton setTitle:title forState:UIControlStateNormal];
    [self.titleButton sizeToFit];
    
    [self.assetsGroup setAssetsFilter:self.assetsFilter];
    ALAssetsGroupEnumerationResultsBlock assetEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result){
            [self.assets addObject:result];
            NSURL *assetURL = [result valueForProperty:ALAssetPropertyAssetURL];
            if ([selectedAssetsSet containsObject:assetURL]) {
                [stillExistingSeletedAssets addObject:assetURL];
            }
        } else {
            [selectedAssetsSet minusSet:stillExistingSeletedAssets];
            NSSet *missingAsset = [NSSet setWithSet:selectedAssetsSet];
            NSMutableArray *assetsToRemove = [NSMutableArray array];
            for (ALAsset *selectedAsset in self.selectedAssets){
                if ([missingAsset containsObject:[selectedAsset valueForProperty:ALAssetPropertyAssetURL]]){
                    [assetsToRemove addObject:selectedAsset];
                }
            }
            [self.selectedAssets removeObjectsInArray:assetsToRemove];
            // Add live data cell
            if ([self isShowingCaptureCell]){
                NSInteger insertPosition = self.showMostRecentFirst ? 0 : self.assets.count;
                [self.assets insertObject:self.liveAsset atIndex:insertPosition];
            }
            // Make sure we reload the collection view
            [self.collectionView reloadData];
            // Scroll to the correct position
            NSInteger sectionToScroll = 0;
            NSInteger itemToScroll = self.showMostRecentFirst ? 0 :self.assets.count-1;
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemToScroll inSection:sectionToScroll] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        }
    };
    [self.assetsGroup enumerateAssetsWithOptions:self.showMostRecentFirst ? NSEnumerationReverse : 0
                                      usingBlock:assetEnumerationBlock];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // load the asset for this cell
    ALAsset *asset = self.assets[indexPath.item];

    if (asset == self.liveAsset) {
        self.captureCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPMediaCaptureCollectionViewCell class]) forIndexPath:indexPath];
        [self.captureCell startCapture];
        return self.captureCell;
    }

    WPMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class]) forIndexPath:indexPath];

    // Configure the cell
    CGImageRef thumbnailImageRef = [asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];

    cell.image = thumbnail;
    NSUInteger position = [self findAsset:asset];
    if (position != NSNotFound) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [cell setPosition:position + 1];
        cell.selected = YES;
    } else {
        [cell setPosition:NSNotFound];
        cell.selected = NO;
    }

    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
        NSNumber *duration = [asset valueForProperty:ALAssetPropertyDuration];
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

- (NSUInteger)findAsset:(ALAsset *)asset
{
    NSUInteger position = [self.selectedAssets indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        ALAsset * loopAsset = (ALAsset *)obj;
        BOOL found =  [[asset valueForProperty:ALAssetPropertyAssetURL]  isEqual:[loopAsset valueForProperty:ALAssetPropertyAssetURL]];
        return found;
    }];
    return position;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = self.assets[indexPath.item];
    // you can always select the capture
    if (self.liveAsset == asset) {
        return YES;
    }

    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        return [self.picker.delegate mediaPickerController:self.picker shouldSelectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = self.assets[indexPath.item];
    if (self.liveAsset == asset) {
        [self.captureCell stopCaptureOnCompletion:^{
            [self captureMedia];
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }];
        return;
    }

    [self.selectedAssets addObject:asset];
    [self.selectedAssetsGroup addObject:self.assetsGroup];
    
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
    ALAsset *asset = self.assets[indexPath.item];
    // you can always deselect the capture
    if (self.liveAsset == asset) {
        return YES;
    }

    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldDeselectAsset:)]) {
        return [self.picker.delegate mediaPickerController:self.picker shouldDeselectAsset:asset];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = self.assets[indexPath.item];
    // check if deselected the capture item
    if (self.liveAsset == asset) {
        return;
    }

    NSUInteger deselectPosition = [self findAsset:asset];
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
    ALAssetsLibraryWriteVideoCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
        if (error){
            self.ignoreMediaNotifications = NO;
            return;
        }
        [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            [self.assetsGroup addAsset:asset];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addAsset:asset];
            });
        } failureBlock:^(NSError *error) {
            self.ignoreMediaNotifications = NO;
            [self loadData];
        }];
    };
    if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeImage]) {
        UIImage *image = (UIImage *)info[UIImagePickerControllerOriginalImage];
        [self.assetsLibrary writeImageToSavedPhotosAlbum:[image CGImage]
                                                metadata:info[UIImagePickerControllerMediaMetadata]
                                         completionBlock:completionBlock];
        
    } else if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeMovie]) {
        [self.assetsLibrary writeVideoAtPathToSavedPhotosAlbum:info[UIImagePickerControllerMediaURL]
                                               completionBlock:completionBlock];
    }
}

- (void)addAsset:(ALAsset *)asset
{
    BOOL willBeSelected = YES;
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]) {
        if ([self.picker.delegate mediaPickerController:self.picker shouldSelectAsset:asset]) {
            [self.selectedAssets addObject:asset];
            [self.selectedAssetsGroup addObject:self.assetsGroup];
        } else {
            willBeSelected = NO;
        }
    } else {
        [self.selectedAssets addObject:asset];
        [self.selectedAssetsGroup addObject:self.assetsGroup];
    }

    NSUInteger insertPosition = [self showMostRecentFirst] ? 1 : self.assets.count - 1;
    [self.assets insertObject:asset atIndex:insertPosition];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:insertPosition inSection:0]]];
    } completion:^(BOOL finished) {
        if ( ![self showMostRecentFirst] ){
            NSUInteger reloadPosition = self.assets.count - 1;
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:reloadPosition inSection:0]]];
        }
        self.ignoreMediaNotifications = NO;
    }];
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

- (void)mediaGroupPickerViewController:(WPMediaGroupPickerViewController *)picker didPickGroup:(ALAssetsGroup *)group
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
        && ![[self class] isiOS8OrAbove]) {
        [self.popOverController dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    self.assetsGroup = group;
    [self loadData];
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
