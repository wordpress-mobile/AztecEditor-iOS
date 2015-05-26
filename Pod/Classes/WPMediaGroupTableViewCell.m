
#import "WPMediaGroupTableViewCell.h"

static CGFloat const WPMediaGroupTableViewCellImagePadding = 2.0;
static CGFloat const WPMediaGroupTableViewCellImageMargin = 15.0;

@implementation WPMediaGroupTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class])];
    if (!self) {
        return nil;
    }
    _imagePosterView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _imagePosterView.contentMode = UIViewContentModeScaleAspectFill;
    _imagePosterView.clipsToBounds = YES;
    [self.contentView addSubview:_imagePosterView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    [self.contentView addSubview:_titleLabel];
    
    _countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _countLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    [self.contentView addSubview:_countLabel];
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat cellHeight = self.contentView.frame.size.height;
    CGFloat imageHeight = cellHeight-(2*WPMediaGroupTableViewCellImagePadding);
    self.imagePosterView.frame = CGRectMake(WPMediaGroupTableViewCellImageMargin, WPMediaGroupTableViewCellImagePadding, imageHeight, imageHeight);

    CGFloat titleFontSize = [self.titleLabel.font ascender] - [self.titleLabel.font descender];
    self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.imagePosterView.frame) + WPMediaGroupTableViewCellImageMargin, (cellHeight/2)-titleFontSize, self.contentView.frame.size.width-CGRectGetMaxX(self.imageView.frame), titleFontSize);
    
    CGFloat countFontSize = [self.countLabel.font ascender] - [self.countLabel.font descender];
    self.countLabel.frame = CGRectMake(CGRectGetMaxX(self.imagePosterView.frame) + WPMediaGroupTableViewCellImageMargin, cellHeight/2, self.contentView.frame.size.width-CGRectGetMaxX(self.imageView.frame), countFontSize);
}

@end
