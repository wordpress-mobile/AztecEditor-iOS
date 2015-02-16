#import "WPMediaCollectionViewController.h"
#import "WPMediaCollectionViewCell.h"
#import "WPMediaCaptureCollectionViewCell.h"
#import "WPMediaPickerViewController.h"
#import "WPMediaGroupPickerViewController.h"

@import AssetsLibrary;
@import MobileCoreServices;
@import AVFoundation;

@interface WPMediaCollectionViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, WPMediaGroupPickerViewControllerDelegate>

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) ALAsset *liveAsset;
@property (nonatomic, strong) WPMediaCaptureCollectionViewCell *captureCell;
@property (nonatomic, strong) UIButton *titleButton;

@end

@implementation WPMediaCollectionViewController

static CGFloat SpaceBetweenPhotos = 2.0f;
static CGFloat NumberOfPhotosForLine = 3;
static CGFloat SelectAnimationTime = 0.2;
static CGFloat MinimumCellSize = 105;
static NSString * const ArrowDown = @"\u25be";

- (instancetype)init {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    self = [self initWithCollectionViewLayout:layout];
    if (self){
        _layout = layout;
        _assets = [[NSMutableArray alloc] init];
        _selectedAssets = [[NSMutableArray alloc] init];
        _allowCaptureOfMedia = YES;
        _showMostRecentFirst = NO;
        _liveAsset = [[ALAsset alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Prepare data structures;
    self.assetsLibrary =  [[ALAssetsLibrary alloc] init];
    
    // Configure collection view behaviour
    self.clearsSelectionOnViewWillAppear = NO;
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    // Register cell classes
    [self.collectionView registerClass:[WPMediaCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([WPMediaCollectionViewCell class])];
    [self.collectionView registerClass:[WPMediaCaptureCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([WPMediaCaptureCollectionViewCell class])];
    
    // Configure collection view layout
    CGFloat width = roundf((self.view.frame.size.width-((NumberOfPhotosForLine-1)*SpaceBetweenPhotos))/NumberOfPhotosForLine);
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
    
    [self loadData];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

-(void)changeGroup:(UIBarButtonItem *)sender
{
    WPMediaGroupPickerViewController *groupViewController = [[WPMediaGroupPickerViewController alloc] init];
    groupViewController.delegate = self;
    groupViewController.assetsLibrary = self.assetsLibrary;
    groupViewController.selectedGroup = self.assetsGroup;
    UINavigationController * groupNavigationController = [[UINavigationController alloc] initWithRootViewController:groupViewController];
    
    [self presentViewController:groupNavigationController animated:YES completion:^{
        
    }];
}

- (void)cancelPicker:(UIBarButtonItem *)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerControllerDidCancel:)]){
        [self.picker.delegate mediaPickerControllerDidCancel:self.picker];
    }
}

- (void)finishPicker:(UIBarButtonItem *)sender
{
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didFinishPickingAssets:)]){
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
    
    NSString *title = [NSString stringWithFormat:@"%@ %@",(NSString *)[self.assetsGroup valueForProperty:ALAssetsGroupPropertyName], ArrowDown];
    [self.titleButton setTitle:title forState:UIControlStateNormal];
    [self.titleButton sizeToFit];
    [self.assetsGroup enumerateAssetsWithOptions:self.showMostRecentFirst ? NSEnumerationReverse:0
                                      usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                          if (result){
                                              [self.assets addObject:result];
                                          } else {
                                              if ([self isShowingCaptureCell]){
                                                  NSInteger insertPosition = self.showMostRecentFirst ? 0 : self.assets.count;
                                                  [self.assets insertObject:self.liveAsset atIndex:insertPosition];
                                              }
                                              [self.collectionView reloadData];
                                              NSInteger sectionToScroll = 0;
                                              NSInteger itemToScroll = self.showMostRecentFirst ? 0 :self.assets.count-1;
                                              [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemToScroll inSection:sectionToScroll] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                                          }
                                      }];
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
    
    if (asset == self.liveAsset){
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
    if (position != NSNotFound){
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        [cell setPosition:position+1];
        cell.selected = YES;
    } else {
        [cell setPosition:NSNotFound];
        cell.selected = NO;
    }
    
    if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo){
        NSNumber * duration = [asset valueForProperty:ALAssetPropertyDuration];
        NSString * caption = [self stringFromTimeInterval:[duration doubleValue]];
        [cell setCaption:caption];
    } else {
        [cell setCaption:@""];
    }
    
    return cell;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger roundedHours = lround(timeInterval / 3600);
    NSInteger roundedMinutes = lround((timeInterval - (3600 * roundedHours)) /60);
    NSInteger roundedSeconds = lround(timeInterval - (roundedHours * 60 * 60) - (roundedMinutes* 60));
    
    if (roundedHours > 0)
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)roundedHours, (long)roundedMinutes, (long)roundedSeconds];
    
    else
        return [NSString stringWithFormat:@"%ld:%02ld", (long)roundedMinutes, (long)roundedSeconds];
}

- (NSUInteger) findAsset:(ALAsset *)asset
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
    ALAsset * asset = self.assets[indexPath.item];
    // you can always select the capture
    if (self.liveAsset == asset){
        return YES;
    }
    
    
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]){
        return [self.picker.delegate mediaPickerController:self.picker shouldSelectAsset:asset];
    }
    return YES;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset * asset = self.assets[indexPath.item];
    if (self.liveAsset == asset) {
        [self.captureCell stopCaptureOnCompletion:^{
            [self captureMedia];
            [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }];
        return;
    }
    
    [self.selectedAssets addObject:asset];
    WPMediaCollectionViewCell * cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell setPosition:self.selectedAssets.count];
    [self animateCellSelection:cell completion:^{
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }];
    
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]){
        [self.picker.delegate mediaPickerController:self.picker didSelectAsset:asset];
    }
}

- (BOOL) collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset * asset = self.assets[indexPath.item];
    // you can always deselect the capture
    if (self.liveAsset == asset) {
        return YES;
    }
    
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldDeselectAsset:)]){
        return [self.picker.delegate mediaPickerController:self.picker shouldDeselectAsset:asset];
    }
    return YES;
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset * asset = self.assets[indexPath.item];
    // check if deselected the capture item
    if (self.liveAsset == asset){
        return;
    }

    
    NSUInteger deselectPosition = [self findAsset:asset];
    if(deselectPosition != NSNotFound) {
        [self.selectedAssets removeObjectAtIndex:deselectPosition];
    }
    
    WPMediaCollectionViewCell * cell = (WPMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self animateCellSelection:cell completion:^{
        [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForSelectedItems];
    }];
    
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didDeselectAsset:)]){
        [self.picker.delegate mediaPickerController:self.picker didDeselectAsset:asset];
    }
}

- (void) animateCellSelection:(UIView *)cell completion:(void(^)())completionBlock
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

- (void) animateCaptureCellSelection:(UIView *)cell completion:(void(^)())completionBlock
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

-(BOOL) isMediaDeviceAvailable
{
    // check if device is capable of capturing photos all together
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

-(void) showMediaCaptureViewController
{
    UIImagePickerController * imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.mediaTypes =
    [UIImagePickerController availableMediaTypesForSourceType:
     UIImagePickerControllerSourceTypeCamera];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:imagePickerController animated:YES completion:^{
        
    }];
}

-(void) captureMedia
{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authorizationStatus == AVAuthorizationStatusAuthorized){
        [self showMediaCaptureViewController];
        return;
    }
    
    if (authorizationStatus == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted)
                {
                        [[[UIAlertView alloc] initWithTitle:@"Media Capture"
                                                    message:@"This app doesn't have permission to use Camera, please change privacy settings"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil] show];
                    return;
                }
                [self showMediaCaptureViewController];
            });
        }];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"Media Capture"
                                    message:@"This app doesn't have permission to use Camera, please change the privacy settings"
                                   delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    });
}

-(void) processMediaCaptured:(NSDictionary *)info
{
    if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeImage]){
        UIImage * image = (UIImage *)info[UIImagePickerControllerOriginalImage];
        [self.assetsLibrary writeImageToSavedPhotosAlbum:[image CGImage] metadata:info[UIImagePickerControllerMediaMetadata] completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error){
                return;
            }
            [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addAsset:asset];
                });
            } failureBlock:^(NSError *error) {
                [self loadData];
            }];
        }];
    } else if ([info[UIImagePickerControllerMediaType] isEqual:(NSString *)kUTTypeMovie]){
        [self.assetsLibrary writeVideoAtPathToSavedPhotosAlbum:info[UIImagePickerControllerMediaURL] completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error){
                return;
            }
            [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addAsset:asset];
                });
            } failureBlock:^(NSError *error) {
                [self loadData];
            }];
        }];
    }
}
     
- (void) addAsset:(ALAsset *)asset
{
    BOOL willBeSelected = YES;
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:shouldSelectAsset:)]){
        if ( [self.picker.delegate mediaPickerController:self.picker shouldSelectAsset:asset]){
            [self.selectedAssets addObject:asset];
        } else {
            willBeSelected = NO;
        }
    } else {
        [self.selectedAssets addObject:asset];
    }

    NSUInteger insertPosition = [self showMostRecentFirst] ? 1 : self.assets.count-1;
    [self.assets insertObject:asset atIndex:insertPosition];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:insertPosition inSection:0]]];
    } completion:^(BOOL finished) {
        if (finished){
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:insertPosition+1 inSection:0]]];
        }
    }];
    if (!willBeSelected){
        return;
    }
    if ([self.picker.delegate respondsToSelector:@selector(mediaPickerController:didSelectAsset:)]){
        [self.picker.delegate mediaPickerController:self.picker didSelectAsset:asset];
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
    self.assetsGroup = group;
    [self loadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)mediaGroupPickerViewControllerDidCancel:(WPMediaGroupPickerViewController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
