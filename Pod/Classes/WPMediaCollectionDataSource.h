typedef NS_ENUM(NSInteger, WPMediaType){
    WPMediaTypeImage,
    WPMediaTypeVideo,
    WPMediaTypeOther,
    WPMediaTypeAll
};

@protocol WPMediaGroup <NSObject>

- (NSString *)name;
- (UIImage *)thumbnailWithSize:(CGSize)size;
- (id)originalGroup;
- (NSString *)identifier;
- (NSInteger)numberOfAssets;

@end

@protocol WPMediaAsset <NSObject>

- (UIImage *)thumbnailWithSize:(CGSize)size;
- (WPMediaType)mediaType;
- (NSNumber *)duration;
- (id)originalAsset;
- (NSString *)identifier;
- (NSDate *)date;

@end

typedef void (^WPMediaChangesBlock)();
typedef void (^WPMediaFailureBlock)(NSError *error);
typedef void (^WPMediaAddedBlock)(id<WPMediaAsset> media, NSError *error);

@protocol WPMediaCollectionDataSource <NSObject>

- (NSInteger)numberOfGroups;

- (id<WPMediaGroup>)groupAtIndex:(NSInteger)index;

- (void)selectGroupAtIndex:(NSInteger)index;

- (id<WPMediaGroup>)selectedGroup;

- (void)setSelectedGroup:(id<WPMediaGroup>)group;

- (NSInteger)numberOfAssets;

- (id<WPMediaAsset>) mediaAtIndex:(NSInteger)index;

- (id<NSObject>)registerChangeObserverBlock:(WPMediaChangesBlock)callback;

- (void)unregisterChangeObserver:(id<NSObject>)blockKey;

- (void)loadDataWithSuccess:(WPMediaChangesBlock)successBlock
                    failure:(WPMediaFailureBlock)failureBlock;

- (void)addImage:(UIImage *)image metadata:(NSDictionary *)metadata completionBlock:(WPMediaAddedBlock)completionBlock;

- (void)addVideoFromURL:(NSURL *)url  completionBlock:(WPMediaAddedBlock)completionBlock;

- (void) setMediaTypeFilter:(WPMediaType)filter;

- (WPMediaType) mediaTypeFilter;

@end

