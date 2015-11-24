#import "WPMediaCollectionViewCell.h"

static const NSTimeInterval ThredsholdForAnimation = 0.03;
static const CGFloat TimeForFadeAnimation = 0.3;

@interface WPMediaCollectionViewCell ()

@property (nonatomic, strong) UILabel *positionLabel;
@property (nonatomic, strong) UIView *selectionFrame;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *captionLabel;

@end

@implementation WPMediaCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    if (self.tag != 0) {
        [self.asset cancelImageRequest:(WPMediaRequestID)self.tag];
    }
    self.tag = 0;
    [self setImage:nil animated:NO];
    [self setCaption:@""];
    [self setPosition:NSNotFound];
    [self setSelected:NO];
}

- (void)commonInit
{
    _imageView = [[UIImageView alloc] init];
    _imageView.isAccessibilityElement = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.backgroundColor = self.backgroundColor;
    self.backgroundView = _imageView;

    _selectionFrame = [[UIView alloc] initWithFrame:self.backgroundView.frame];
    _selectionFrame.layer.borderColor = [[self tintColor] CGColor];
    _selectionFrame.layer.borderWidth = 3;

    CGFloat counterTextSize = [UIFont smallSystemFontSize];
    CGFloat labelSize = (counterTextSize * 2) + 2;
    _positionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelSize, labelSize)];
    _positionLabel.backgroundColor = [self tintColor];
    _positionLabel.textColor = [UIColor whiteColor];
    _positionLabel.textAlignment = NSTextAlignmentCenter;
    _positionLabel.font = [UIFont systemFontOfSize:counterTextSize];

    [_selectionFrame addSubview:_positionLabel];

    self.selectedBackgroundView = _selectionFrame;

    _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.contentView.frame.size.height - counterTextSize, self.contentView.frame.size.width, counterTextSize)];
    _captionLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
    _captionLabel.hidden = YES;
    _captionLabel.textColor = [UIColor whiteColor];
    _captionLabel.textAlignment = NSTextAlignmentRight;
    _captionLabel.font = [UIFont systemFontOfSize:counterTextSize - 2];
    [self.contentView addSubview:_captionLabel];
}

- (void)setAsset:(id<WPMediaAsset>)asset {
    _asset = asset;
    __block WPMediaRequestID requestKey = 0;
    NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
    requestKey = [_asset imageWithSize:self.frame.size completionHandler:^(UIImage *result, NSError *error) {
        BOOL animated = ([NSDate timeIntervalSinceReferenceDate] - timestamp) > ThredsholdForAnimation;
        if (error) {
            self.image = nil;
            NSLog(@"%@", [error localizedDescription]);
            return;
        }
        // Did this request changed meanwhile
        if (requestKey != self.tag) {
            return;
        }
        if ([NSThread isMainThread]){
            [self setImage:result
                  animated:animated];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setImage:result
                      animated:animated];
            });
        }
    }];
    self.tag = requestKey;
    NSString *label = @"";
    NSString *caption = @"";
    WPMediaType assetType = _asset.assetType;
    switch (assetType) {
        case WPMediaTypeImage:
            label = [NSString stringWithFormat:NSLocalizedString(@"Image, %@", @"Accessibility label for image thumbnails in the media collection view. The parameter is the creation date of the image."),
                     [[[self class] dateFormatter] stringFromDate:_asset.date]];
        break;
        case WPMediaTypeVideo:
            label = [NSString stringWithFormat:NSLocalizedString(@"Video, %@", @"Accessibility label for video thumbnails in the media collection view. The parameter is the creation date of the video."),
                     [[[self class] dateFormatter] stringFromDate:_asset.date]];
            NSTimeInterval duration = [asset duration];
            caption = [self stringFromTimeInterval:duration];
        break;
        default:
        break;
    }
    self.imageView.accessibilityLabel = label;
    [self setCaption:caption];
}

+ (NSDateFormatter *) dateFormatter {
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    });
    
    return _dateFormatter;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger roundedHours = floor(timeInterval / 3600);
    NSInteger roundedMinutes = floor((timeInterval - (3600 * roundedHours)) / 60);
    NSInteger roundedSeconds = round(timeInterval - (roundedHours * 60 * 60) - (roundedMinutes * 60));
    
    if (roundedHours > 0)
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)roundedHours, (long)roundedMinutes, (long)roundedSeconds];
    
    else
        return [NSString stringWithFormat:@"%ld:%02ld", (long)roundedMinutes, (long)roundedSeconds];
}

- (void)setImage:(UIImage *)image
{
    [self setImage:image animated:YES];
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated
{
    if (!image){
        self.imageView.alpha = 0;
        self.imageView.image = nil;
    } else {
        if (animated) {
            [UIView animateWithDuration:TimeForFadeAnimation animations:^{
                self.imageView.alpha = 1.0;
                self.imageView.image = image;
            }];
        } else {
            self.imageView.alpha = 1.0;
            self.imageView.image = image;
        }
    }
}

- (void)setPosition:(NSInteger)position
{
    _position = position;
    self.positionLabel.hidden = position == NSNotFound;
    self.positionLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)(position)];
}

- (void)setCaption:(NSString *)caption
{
    self.captionLabel.hidden = !(caption.length > 0);
    self.captionLabel.text = caption;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (self.isSelected) {
        _captionLabel.backgroundColor = [self tintColor];
    } else {
        self.positionLabel.hidden = YES;
        _captionLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
    }
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    _selectionFrame.layer.borderColor = [[self tintColor] CGColor];
    _positionLabel.backgroundColor = [self tintColor];
    if (self.isSelected) {
        _captionLabel.backgroundColor = [self tintColor];
    } else {
        _captionLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
    }
}

@end
