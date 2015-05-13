#import "WPPHAssetDataSource.h"
@import Photos;

@interface WPPHAssetDataSource  ()

@property (nonatomic, strong) PHAssetCollection *assetsGroup;
@property (nonatomic, strong) PHFetchResult *groups;
@property (nonatomic, strong) PHFetchResult *assets;
@property (nonatomic, assign) BOOL ignoreMediaNotifications;
@property (nonatomic, assign) WPMediaType mediaTypeFilter;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, assign) BOOL refreshGroups;

@end

@implementation WPPHAssetDataSource

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _mediaTypeFilter = WPMediaTypeAll;
    _observers = [[NSMutableDictionary alloc] init];
    _refreshGroups = YES;
    return self;
}

- (void)dealloc
{
    
}

+ (PHImageManager *) sharedImageManager {
    static id _sharedImageManager = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedImageManager = [[PHCachingImageManager alloc] init];
    });
    
    return _sharedImageManager;
}

- (void)handleLibraryNotification:(NSNotification *)note
{
    if (![self shouldNotifyObservers:note]) {
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf loadDataWithSuccess:^{
            [weakSelf.observers enumerateKeysAndObjectsUsingBlock:^(NSUUID *key, WPMediaChangesBlock block, BOOL *stop) {
                block();
            }];
        } failure:nil];
    });
}

- (BOOL)shouldNotifyObservers:(NSNotification *)note
{
    return NO;
}

- (PHPhotoLibrary *)assetsLibrary
{
    return [PHPhotoLibrary sharedPhotoLibrary];
}

- (void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock
{
    if (self.refreshGroups) {
        [self loadGroupsWithSuccess:^{
            self.refreshGroups = NO;
            [self loadAssetsWithSuccess:successBlock failure:failureBlock];
        } failure:failureBlock];
    } else {
        [self loadAssetsWithSuccess:successBlock failure:failureBlock];
    }
}

- (void)loadGroupsWithSuccess:(WPMediaChangesBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{
    self.groups = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    if (self.groups.count > 0){
        self.assetsGroup = self.groups[0];
        if (successBlock) {
            successBlock();
        }
    } else {
        if (failureBlock) {
            failureBlock(nil);
        }

    }
    
}

- (void)loadAssetsWithSuccess:(WPMediaChangesBlock)successBlock
                      failure:(WPMediaFailureBlock)failureBlock
{
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    if (self.mediaTypeFilter != WPMediaTypeAll) {
        PHAssetMediaType mediaType = PHAssetMediaTypeUnknown;
        if(self.mediaTypeFilter == WPMediaTypeVideo){
            mediaType = PHAssetMediaTypeVideo;
        } else if (self.mediaTypeFilter == WPMediaTypeImage){
            mediaType = PHAssetMediaTypeImage;
        }
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d)", mediaType];
    }
    self.assets = [PHAsset fetchAssetsInAssetCollection:self.assetsGroup options:fetchOptions];
    if (successBlock) {
        successBlock();
    }
}

#pragma mark - WPMediaCollectionDataSource

- (NSInteger)numberOfGroups
{
    return self.groups.count;
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index
{
    return [[WPPHAssetCollection alloc] initWithAssetCollection:self.groups[index]];
}

- (void)selectGroupAtIndex:(NSInteger)index
{
    self.assetsGroup = self.groups[index];
}

- (id<WPMediaGroup>)selectedGroup
{
    return [[WPPHAssetCollection alloc] initWithAssetCollection:self.assetsGroup];
}

- (void)setSelectedGroup:(id<WPMediaGroup>)group
{
    NSParameterAssert([group isKindOfClass:[WPPHAssetCollection class]]);
    self.assetsGroup = (PHAssetCollection *)[group originalGroup];
}

- (NSInteger)indexOfSelectedGroup
{
    return NSNotFound;
}

- (NSInteger)numberOfAssets
{
    return self.assets.count;
}

- (id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return [[WPPHAssetMedia alloc] initWithAsset:self.assets[index]];
}

- (id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    NSUUID *blockKey = [NSUUID UUID];
    [self.observers setObject:[callback copy] forKey:blockKey];
    return blockKey;
    
}

- (void)unregisterChangeObserver:(id<NSObject>)blockKey
{
    [self.observers removeObjectForKey:blockKey];
}

- (void)addImage:(UIImage *)image
        metadata:(NSDictionary *)metadata
 completionBlock:(WPMediaAddedBlock)completionBlock
{
//    self.ignoreMediaNotifications = YES;
//    [self.assetsLibrary writeImageToSavedPhotosAlbum:[image CGImage]
//                                            metadata:metadata
//                                     completionBlock:^(NSURL *assetURL, NSError *error)
//     {
//         if (error){
//             self.ignoreMediaNotifications = NO;
//             return;
//         }
//         [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
//             [self.assets addObject:asset];
//             [self.assetsGroup addAsset:asset];
//             WPALAssetMedia *mediaDetail = [[WPALAssetMedia alloc] initWithAsset:asset];
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 if (completionBlock) {
//                     completionBlock(mediaDetail, nil);
//                 }
//                 self.ignoreMediaNotifications = NO;
//             });
//         } failureBlock:^(NSError *error) {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 if (completionBlock) {
//                     completionBlock(nil, error);
//                 }
//                 self.ignoreMediaNotifications = NO;
//             });
//         }];
//     }];
}

- (void)addVideoFromURL:(NSURL *)url
        completionBlock:(WPMediaAddedBlock)completionBlock
{
//    self.ignoreMediaNotifications = YES;
//    [self.assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url
//                                           completionBlock:^(NSURL *assetURL, NSError *error)
//     {
//         if (error){
//             self.ignoreMediaNotifications = NO;
//             return;
//         }
//         [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
//             [self.assets addObject:asset];
//             [self.assetsGroup addAsset:asset];
//             WPALAssetMedia *mediaDetail = [[WPALAssetMedia alloc] initWithAsset:asset];
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 if (completionBlock) {
//                     completionBlock(mediaDetail, nil);
//                 }
//                 self.ignoreMediaNotifications = NO;
//             });
//         } failureBlock:^(NSError *error) {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 if (completionBlock) {
//                     completionBlock(nil, error);
//                 }
//                 self.ignoreMediaNotifications = NO;
//             });
//         }];
//     }];
}

- (void)setMediaTypeFilter:(WPMediaType)filter
{
    _mediaTypeFilter = filter;
}

@end

#pragma mark - WPALAssetMedia

@interface WPPHAssetMedia()

@property (nonatomic, strong) PHAsset *asset;

@end

@implementation WPPHAssetMedia

- (instancetype)initWithAsset:(PHAsset *)asset
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _asset = asset;
    return self;
}

- (UIImage *)thumbnailWithSize:(CGSize)size
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize realSize = CGSizeApplyAffineTransform(size, CGAffineTransformMakeScale(scale, scale));
    options.synchronous = YES;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    __block UIImage *thumbnail = nil;
    [[WPPHAssetDataSource sharedImageManager] requestImageForAsset:self.asset
                                                        targetSize:realSize
                                                       contentMode:PHImageContentModeAspectFill
                                                           options:options
                                                     resultHandler:^(UIImage *result, NSDictionary *info) {
                                                         thumbnail = result;
                                                     }];
    return thumbnail;
}

- (WPMediaType)mediaType
{
    if ([self.asset mediaType] == PHAssetMediaTypeVideo){
        return WPMediaTypeVideo;
    } else if ([self.asset mediaType] == PHAssetMediaTypeImage) {
        return WPMediaTypeImage;
    } else if ([self.asset mediaType] == PHAssetMediaTypeUnknown) {
        return WPMediaTypeOther;
    }
    
    return WPMediaTypeOther;
}

- (NSNumber *)duration
{
    NSNumber * duration = nil;
    if ([self.asset mediaType] == PHAssetMediaTypeVideo) {
        duration = @([self.asset duration]);
    }
    return duration;
}

- (id)originalAsset
{
    return self.asset;
}

- (NSString *)identifier
{
    return [self.asset localIdentifier];
}

- (NSDate *)date
{
    return [self.asset creationDate];
}

@end

#pragma mark - WPPHAssetCollection

@interface WPPHAssetCollection()

@property (nonatomic, strong) PHAssetCollection *assetsGroup;

@end

@implementation WPPHAssetCollection

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetsGroup
{
    self = [super init];
    if (!self){
        return nil;
    }
    _assetsGroup = assetsGroup;
    return self;
}

- (NSString *)name
{
    return [self.assetsGroup localizedTitle];
}

- (UIImage *)thumbnailWithSize:(CGSize)size
{
    return nil;
}

- (id)originalGroup
{
    return self.assetsGroup;
}

- (NSString *)identifier
{
    return [self.assetsGroup localIdentifier];
}

- (NSInteger)numberOfAssets
{
    NSInteger count = [self.assetsGroup estimatedAssetCount];
    if ( count == NSNotFound) {
        count = [[PHAsset fetchAssetsInAssetCollection:self.assetsGroup options:nil] count];
    }
    return count;
}

@end
