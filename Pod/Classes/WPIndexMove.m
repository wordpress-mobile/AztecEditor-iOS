#import "WPIndexMove.h"

@interface WPIndexMove()

@property (nonatomic, assign) NSUInteger from;
@property (nonatomic, assign) NSUInteger to;

@end

@implementation WPIndexMove

- (instancetype)init:(NSUInteger)from to:(NSUInteger)to
{
    self = [super init];
    if (self) {
        _from = from;
        _to = to;
    }
    return self;
}
@end
