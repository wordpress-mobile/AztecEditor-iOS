
#import "WPMediaGroupTableViewCell.h"

static CGFloat const WPMediaGroupTableViewCellImagePadding = 8.0;
static CGFloat const WPMediaGroupTableViewCellImageMargin = 8.0;
static CGFloat const WPMediaGroupTableViewCellLabelMargin = 15.0;
static CGFloat const WPMediaGroupTableViewCellCountLabelMargin = 2.0;

@implementation WPMediaGroupTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([WPMediaGroupTableViewCell class])];
    if (!self) {
        return nil;
    }
    _posterBackgroundColor = UIColor.lightGrayColor;

    _imagePosterView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _imagePosterView.contentMode = UIViewContentModeScaleAspectFill;
    _imagePosterView.clipsToBounds = YES;
    _imagePosterView.translatesAutoresizingMaskIntoConstraints = NO;
    _imagePosterView.backgroundColor = _posterBackgroundColor;
    [self.contentView addSubview:_imagePosterView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_titleLabel];
    
    _countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _countLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _countLabel.textColor = [UIColor lightGrayColor];
    [self.contentView addSubview:_countLabel];

    [_imagePosterView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:WPMediaGroupTableViewCellImageMargin].active = YES;
    [_imagePosterView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:WPMediaGroupTableViewCellImagePadding].active = YES;
    [_imagePosterView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-WPMediaGroupTableViewCellImagePadding].active = YES;
    [_imagePosterView.widthAnchor constraintEqualToAnchor:_imagePosterView.heightAnchor].active = YES;
    [_titleLabel.leadingAnchor constraintEqualToAnchor:_imagePosterView.trailingAnchor constant:WPMediaGroupTableViewCellLabelMargin].active = YES;
    [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
    [_titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;    
    [_countLabel.leadingAnchor constraintEqualToAnchor:_imagePosterView.trailingAnchor constant:WPMediaGroupTableViewCellLabelMargin].active = YES;
    [_countLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
    [_countLabel.topAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:WPMediaGroupTableViewCellCountLabelMargin].active = YES;

    return self;
}

- (void)setPosterBackgroundColor:(UIColor *)posterBackgroundColor {
    _posterBackgroundColor = posterBackgroundColor;
    _imagePosterView.backgroundColor = posterBackgroundColor;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imagePosterView.image = nil;
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
    self.groupIdentifier = nil;
}

@end
