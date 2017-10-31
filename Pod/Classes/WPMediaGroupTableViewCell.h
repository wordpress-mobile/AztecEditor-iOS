@import UIKit;

@interface WPMediaGroupTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *imagePosterView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UIColor *posterBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSString *groupIdentifier;

@end
