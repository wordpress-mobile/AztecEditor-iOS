#import "WPMediaCollectionViewCell.h"
#import "WPMediaPickerResources.h"

static const NSTimeInterval ThresholdForAnimation = 0.03;
static const CGFloat TimeForFadeAnimation = 0.3;

@interface WPMediaCollectionViewCell ()

@property (nonatomic, strong) UILabel *positionLabel;
@property (nonatomic, strong) UIView *selectionFrame;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *captionLabel;

@property (nonatomic, strong) UIStackView *placeholderStackView;
@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong) UILabel *documentExtensionLabel;

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
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.backgroundColor = self.backgroundColor;

    self.placeholderStackView.hidden = YES;
    self.documentExtensionLabel.text = nil;
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
    _captionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    [self.contentView addSubview:_captionLabel];

    _placeholderStackView = [UIStackView new];
    _placeholderStackView.hidden = YES;
    _placeholderStackView.axis = UILayoutConstraintAxisVertical;
    _placeholderStackView.alignment = UIStackViewAlignmentCenter;
    _placeholderStackView.distribution = UIStackViewDistributionEqualSpacing;
    _placeholderStackView.spacing = 8.0;

    _documentExtensionLabel = [UILabel new];
    _documentExtensionLabel.textAlignment = NSTextAlignmentCenter;
    _documentExtensionLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
    _documentExtensionLabel.textColor = _placeholderTintColor;

    _placeholderImageView = [UIImageView new];
    _placeholderImageView.contentMode = UIViewContentModeCenter;

    [_placeholderStackView addArrangedSubview:_placeholderImageView];
    [_placeholderStackView addArrangedSubview:_documentExtensionLabel];

    UIStackView *wrapper = [[UIStackView alloc] initWithFrame:self.bounds];
    wrapper.axis = UILayoutConstraintAxisHorizontal;
    wrapper.alignment = UIStackViewAlignmentCenter;
    [self.contentView addSubview:wrapper];
    wrapper.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [wrapper addArrangedSubview:_placeholderStackView];
}

- (void)displayAssetTypePlaceholder
{
    self.placeholderStackView.hidden = NO;
    self.imageView.hidden = YES;
    UIImage * iconImage = nil;
    NSString *caption = nil;
    NSString *extension = nil;
    NSString *accessibilityLabel = @"";
    NSString *formattedDate = [[[self class] dateFormatter] stringFromDate:_asset.date];
    if ([self.asset respondsToSelector:@selector(filename)]) {
        caption = [self.asset filename];
    }

    switch (self.asset.assetType) {
        case WPMediaTypeImage:
            iconImage = [WPMediaPickerResources imageNamed:@"gridicons-camera" withExtension:@"png"];
            extension = NSLocalizedString(@"IMAGE", @"Label displayed on audio media items.");
            caption = nil;
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Image, %@", @"Accessibility label for image thumbnails in the media collection view. The parameter is the creation date of the image."), formattedDate];
            break;
        case WPMediaTypeVideo:
            iconImage = [WPMediaPickerResources imageNamed:@"gridicons-video-camera" withExtension:@"png"];
            extension = NSLocalizedString(@"VIDEO", @"Label displayed on audio media items.");
            caption = [self stringFromTimeInterval:[self.asset duration]];
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Video, %@", @"Accessibility label for video thumbnails in the media collection view. The parameter is the creation date of the video."), formattedDate];
            break;
        case WPMediaTypeAudio:
            iconImage = [WPMediaPickerResources imageNamed:@"gridicons-audio" withExtension:@"png"];
            extension = NSLocalizedString(@"AUDIO", @"Label displayed on audio media items.");
            caption = [self stringFromTimeInterval:[self.asset duration]];
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Audio, %@", @"Accessibility label for audio items in the media collection view. The parameter is the creation date of the audio."), formattedDate];
            break;
        case WPMediaTypeOther:
            iconImage = [WPMediaPickerResources imageNamed:@"gridicons-pages" withExtension:@"png"];
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Document: %@", @"Accessibility label for other media items in the media collection view. The parameter is the filename file."), [_asset filename]];
            break;
        default:
            break;
    }
    if ([self.asset respondsToSelector:@selector(fileExtension)]) {
        extension = [[self.asset fileExtension] uppercaseString];
    }
    self.placeholderImageView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self setCaption:caption];
    self.documentExtensionLabel.text = extension;
    self.accessibilityLabel = accessibilityLabel;
}



- (void)setAsset:(id<WPMediaAsset>)asset {
    _asset = asset;

    WPMediaType assetType = _asset.assetType;
    switch (assetType) {
        case WPMediaTypeImage:
        case WPMediaTypeVideo:
            [self fetchAssetImage];
            break;
        case WPMediaTypeAudio:
        case WPMediaTypeOther:
            [self displayAssetTypePlaceholder];
        default:
        break;
    }


}

- (void)fetchAssetImage
{
    __block WPMediaRequestID requestKey = 0;
    NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize requestSize = CGSizeApplyAffineTransform(self.frame.size, CGAffineTransformMakeScale(scale, scale));

    requestKey = [_asset imageWithSize:requestSize completionHandler:^(UIImage *result, NSError *error) {
        if (error || result == nil) {
            [self displayAssetTypePlaceholder];
            return;
        }
        // Did this request changed meanwhile
        if (requestKey != self.tag) {
            return;
        }
        if (_asset.assetType == WPMediaTypeVideo || _asset.assetType == WPMediaTypeAudio) {
            NSString *caption = [self stringFromTimeInterval:[self.asset duration]];
            [self setCaption:caption];
        }
        self.imageView.hidden = NO;
        self.placeholderStackView.hidden = YES;
        BOOL animated = ([NSDate timeIntervalSinceReferenceDate] - timestamp) > ThresholdForAnimation;
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

- (void)setPlaceholderTintColor:(UIColor *)placeholderTintColor
{
    _placeholderTintColor = placeholderTintColor;
    _placeholderImageView.tintColor = placeholderTintColor;
    _documentExtensionLabel.textColor = placeholderTintColor;
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
