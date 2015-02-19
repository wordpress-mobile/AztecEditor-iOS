
#import "WPMediaGroupTableViewCell.h"

static CGFloat const WPMediaGroupTableViewCellImagePadding = 2.0;

@implementation WPMediaGroupTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class])];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = CGRectInset(self.imageView.frame, WPMediaGroupTableViewCellImagePadding, WPMediaGroupTableViewCellImagePadding);
}

@end
