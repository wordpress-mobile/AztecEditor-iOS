@import Foundation;

#import "WPMediaCollectionDataSource.h"

@interface WPIndexMove : NSObject<WPMediaMove>

@property (nonatomic, assign, readonly) NSUInteger from;
@property (nonatomic, assign, readonly) NSUInteger to;

- (instancetype)init:(NSUInteger)from to:(NSUInteger)to;

@end
