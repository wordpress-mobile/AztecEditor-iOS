#import "WPALAssetDataSource.h"

@import AssetsLibrary;

@interface WPALAssetDataSource  ()

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSMutableArray *selectedAssetsGroup;
@property (nonatomic, assign) BOOL ignoreMediaNotifications;
@property (nonatomic, copy) WPMediaChangesBlock mediaChangesCallbackBlock;
@property (nonatomic, assign) WPMediaType filter;
@property (nonatomic, strong) ALAssetsFilter *assetsFilter;
@end

@implementation WPALAssetDataSource

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLibraryNotification:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:self.assetsLibrary];
    _groups = [[NSMutableArray alloc] init];
    _assets = [[NSMutableArray alloc] init];
    _selectedAssets = [[NSMutableArray alloc] init];
    _selectedAssetsGroup = [[NSMutableArray alloc] init];
    _filter = WPMediaTypeAll;
    _assetsFilter = [ALAssetsFilter allAssets];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
            [self loadDataWithSuccess:self.mediaChangesCallbackBlock failure:nil];
        });
    }
}

- (ALAssetsLibrary *)assetsLibrary
{
    static dispatch_once_t onceToken;
    static ALAssetsLibrary *_assetsLibrary;
    dispatch_once(&onceToken, ^{
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    });
    return _assetsLibrary;
}

#pragma mark - WPMediaCollectionDataSource

- (NSInteger)numberOfGroups
{
    return self.groups.count;
}

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index {
   return [[WPALAssetGroup alloc] initWithAssetsGroup:self.groups[index]];
}

- (void)selectGroupAtIndex:(NSInteger)index
{
    self.assetsGroup = (ALAssetsGroup *)[self.groups[index] originalGroup];
}

- (id<WPMediaGroup>)selectedGroup
{
    return [[WPALAssetGroup alloc] initWithAssetsGroup:self.assetsGroup];
}

- (void)setSelectedGroup:(id<WPMediaGroup>)group
{
    NSParameterAssert([group isKindOfClass:[WPALAssetGroup class]]);
    self.assetsGroup = (ALAssetsGroup *)[group originalGroup];
}

- (NSInteger)indexOfSelectedGroup
{
    for (int i = 0; i < self.groups.count; i++) {
        ALAssetsGroup *group = (ALAssetsGroup *)self.groups[i];
        NSURL *loopGroupURL = [group valueForProperty:ALAssetsGroupPropertyURL];
        if ([loopGroupURL isEqual:[self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL]]) {
            return i;
        }
    }
    return NSNotFound;
}

- (NSInteger)numberOfAssets
{
    return self.assets.count;
}

- (id<WPMediaAsset>)mediaAtIndex:(NSInteger)index
{
    return [[WPALAssetDetail alloc] initWithAsset:self.assets[index]];
}

- (void)registerChangeObserverBlock:(WPMediaChangesBlock)callback
{
    self.mediaChangesCallbackBlock = callback;
}

- (void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock
                failure:(WPMediaFailureBlock)failureBlock {
    [self.assets removeAllObjects];
    if (!self.assetsGroup){
        [self.groups removeAllObjects];
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if(!group){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadDataWithSuccess:successBlock failure:failureBlock];
                });
                return;
            }
            [self.groups addObject:group];
            if (!self.assetsGroup){
                if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos){
                    self.assetsGroup = group;
                }
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            if (failureBlock) {
                failureBlock(error);
            }
        }];
    }
    
    [self.assetsGroup setAssetsFilter:self.assetsFilter];
    ALAssetsGroupEnumerationResultsBlock assetEnumerationBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (asset){
            [self.assets addObject:asset];
        } else {
            if (successBlock) {
                successBlock();
            }
        }
    };
    [self.assetsGroup enumerateAssetsWithOptions: 0
                                      usingBlock:assetEnumerationBlock];
}

- (void)addImage:(UIImage *)image
        metadata:(NSDictionary *)metadata
 completionBlock:(WPMediaAddedBlock)completionBlock
{
    self.ignoreMediaNotifications = YES;
    [self.assetsLibrary writeImageToSavedPhotosAlbum:[image CGImage]
                                            metadata:metadata
                                     completionBlock:^(NSURL *assetURL, NSError *error)
    {
        if (error){
            self.ignoreMediaNotifications = NO;
            return;
        }
        [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            [self.assets addObject:asset];
            [self.assetsGroup addAsset:asset];
            WPALAssetDetail *mediaDetail = [[WPALAssetDetail alloc] initWithAsset:asset];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(mediaDetail, nil);
                }
                self.ignoreMediaNotifications = NO;
            });
        } failureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionBlock) {
                    completionBlock(nil, error);
                }
                self.ignoreMediaNotifications = NO;
            });
        }];
    }];
}

- (void)addVideoFromURL:(NSURL *)url
        completionBlock:(WPMediaAddedBlock)completionBlock
{
    self.ignoreMediaNotifications = YES;
    [self.assetsLibrary writeVideoAtPathToSavedPhotosAlbum:url
                                           completionBlock:^(NSURL *assetURL, NSError *error)
    {
       if (error){
           self.ignoreMediaNotifications = NO;
           return;
       }
       [self.assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
           [self.assets addObject:asset];
           [self.assetsGroup addAsset:asset];
           WPALAssetDetail *mediaDetail = [[WPALAssetDetail alloc] initWithAsset:asset];
           dispatch_async(dispatch_get_main_queue(), ^{
               if (completionBlock) {
                   completionBlock(mediaDetail, nil);
               }
               self.ignoreMediaNotifications = NO;
           });
       } failureBlock:^(NSError *error) {
           dispatch_async(dispatch_get_main_queue(), ^{
               if (completionBlock) {
                   completionBlock(nil, error);
               }
               self.ignoreMediaNotifications = NO;
           });
       }];
    }];
}

- (void) setMediaTypeFilter:(WPMediaType)filter
{
    self.filter = filter;
    switch (self.filter) {
        case WPMediaTypeAll:
            self.assetsFilter = [ALAssetsFilter allAssets];
            break;
        case WPMediaTypeImage:
            self.assetsFilter = [ALAssetsFilter allPhotos];
            break;
        case WPMediaTypeVideo:
            self.assetsFilter = [ALAssetsFilter allVideos];
            break;
        default:
            self.assetsFilter = [ALAssetsFilter allAssets];
            break;
    }}

- (WPMediaType)mediaTypeFilter
{
    return self.filter;
}

@end

#pragma mark - WPALAssetDetail

@interface WPALAssetDetail()

@property (nonatomic, strong) ALAsset *asset;

@end

@implementation WPALAssetDetail

- (instancetype)initWithAsset:(ALAsset *)asset
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _asset = asset;
    return self;
}

- (UIImage *)thumbnailWithSize:(CGSize)size {
    CGImageRef thumbnailImageRef = [self.asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    return thumbnail;
}

- (WPMediaType)mediaType {
    if ([self.asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo){
        return WPMediaTypeVideo;
    } else if ([self.asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
        return WPMediaTypeImage;
    } else if ([self.asset valueForProperty:ALAssetPropertyType] == ALAssetTypeUnknown) {
        return WPMediaTypeOther;
    }
    
    return WPMediaTypeOther;
}

- (NSNumber *)duration {
    NSNumber * duration = nil;
    if ([self.asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
        duration = [self.asset valueForProperty:ALAssetPropertyDuration];
    }
    return duration;
}

- (id)originalAsset {
    return self.asset;
}

- (NSString *)identifier {
    return [[self.asset valueForProperty:ALAssetPropertyAssetURL] absoluteString];
}

- (NSDate *)date {
    return [self.asset valueForProperty:ALAssetPropertyDate];
}

@end

#pragma mark - WPALAssetGroup

@interface WPALAssetGroup()

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;

@end

@implementation WPALAssetGroup

- (instancetype)initWithAssetsGroup:(ALAssetsGroup *)assetsGroup
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
    return [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
}

- (UIImage *)thumbnailWithSize:(CGSize)size
{
    return [UIImage imageWithCGImage:[self.assetsGroup posterImage]];
}

- (id)originalGroup
{
    return self.assetsGroup;
}

- (NSString *)identifier
{
    return [[self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL] absoluteString];
}

- (NSInteger)numberOfAssets
{
    return self.assetsGroup.numberOfAssets;
}

@end

