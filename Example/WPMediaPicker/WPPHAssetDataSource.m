#import "WPPHAssetDataSource.h"
@import Photos;

@interface WPPHAssetDataSource() <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHAssetCollection *assetsGroup;
@property (nonatomic, strong) PHFetchResult *groups;
@property (nonatomic, strong) PHFetchResult *assets;
@property (nonatomic, assign) BOOL ignoreMediaNotifications;
@property (nonatomic, assign) WPMediaType mediaTypeFilter;
@property (nonatomic, strong) NSMutableDictionary *observers;
@property (nonatomic, assign) BOOL refreshGroups;

@end

@implementation WPPHAssetDataSource

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _mediaTypeFilter = WPMediaTypeAll;
    _observers = [[NSMutableDictionary alloc] init];
    _refreshGroups = YES;
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

+ (PHImageManager *) sharedImageManager {
    static id _sharedImageManager = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _sharedImageManager = [[PHCachingImageManager alloc] init];
    });
    
    return _sharedImageManager;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    PHFetchResultChangeDetails *groupChangeDetails = [changeInstance changeDetailsForFetchResult:self.groups];
    PHFetchResultChangeDetails *assetsChangeDetails = [changeInstance changeDetailsForFetchResult:self.assets];
    
    if (!groupChangeDetails && !assetsChangeDetails) {
        return;
    }
    
    if (groupChangeDetails){
        self.refreshGroups = YES;
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
    return !self.ignoreMediaNotifications;
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
    self.groups = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                           subtype:PHAssetCollectionSubtypeAny
                                                           options:nil];
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
    self.ignoreMediaNotifications = YES;
    __block NSString * assetIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        assetIdentifier = [assetPlaceholder localIdentifier];
        if ([self.assetsGroup canPerformEditOperation:PHCollectionEditOperationAddContent]) {
            // Request editing the album.
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.assetsGroup];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        self.ignoreMediaNotifications = NO;
        if (!success) {
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, error);
                });
            }
            return;
        }
        PHFetchResult * result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetIdentifier] options:nil];
        if (result.count < 1){
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        [self loadAssetsWithSuccess:nil failure:nil];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                WPPHAssetMedia *assetMedia = [[WPPHAssetMedia alloc] initWithAsset:result[0]];
                completionBlock(assetMedia, nil);
            });
        }
    }];
}

- (void)addVideoFromURL:(NSURL *)url
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    self.ignoreMediaNotifications = YES;
    __block NSString * assetIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        assetIdentifier = [assetPlaceholder localIdentifier];
        if ([self.assetsGroup canPerformEditOperation:PHCollectionEditOperationAddContent]) {
            // Request editing the album.
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.assetsGroup];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        self.ignoreMediaNotifications = NO;
        if (!success) {
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        PHFetchResult * result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetIdentifier] options:nil];
        if (result.count < 1){
            if (completionBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
            }
            return;
        }
        [self loadAssetsWithSuccess:nil failure:nil];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                WPPHAssetMedia *assetMedia = [[WPPHAssetMedia alloc] initWithAsset:result[0]];
                completionBlock(assetMedia, nil);
            });
        }
    }];
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
