#import "WPMediaCollectionViewCell.h"
#import "WPMediaPickerResources.h"
#import "WPDateTimeHelpers.h"

static const NSTimeInterval ThresholdForAnimation = 0.03;
static const CGFloat TimeForFadeAnimation = 0.3;

@interface WPMediaCollectionViewCell ()

@property (nonatomic, strong) UILabel *positionLabel;
@property (nonatomic, strong) UIView *selectionFrame;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) UIView *gradientView;

@property (nonatomic, strong) UIStackView *placeholderStackView;
@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong) UILabel *documentExtensionLabel;

@property (nonatomic, assign) WPMediaRequestID requestKey;

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
    if (self.requestKey != 0) {
        [self.asset cancelImageRequest:self.requestKey];
    }
    self.requestKey = 0;
    [self setImage:nil animated:NO];
    [self setCaption:@""];
    [self setPosition:NSNotFound];
    [self setSelected:NO];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.backgroundColor = self.backgroundColor;

    self.placeholderStackView.hidden = YES;
    self.documentExtensionLabel.text = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientView.layer.sublayers.firstObject.frame = self.gradientView.bounds;
}

- (void)commonInit
{
    self.isAccessibilityElement = YES;
    _imageView = [[UIImageView alloc] init];
    _imageView.isAccessibilityElement = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.backgroundColor = self.backgroundColor;
    self.backgroundView = _imageView;

    _selectionFrame = [[UIView alloc] initWithFrame:self.backgroundView.frame];
    _selectionFrame.layer.borderColor = [[self tintColor] CGColor];
    _selectionFrame.layer.borderWidth = 3.0;

    CGFloat labelMargin = 10.0;
    CGFloat labelSize = 20;
    _positionLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelMargin, self.contentView.frame.size.height - (labelSize + labelMargin), labelSize, labelSize)];
    _positionLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _positionLabel.layer.borderWidth = 1.0;
    _positionLabel.layer.cornerRadius = labelSize / 2;
    _positionLabel.clipsToBounds = YES;
    _positionLabel.textColor = [UIColor whiteColor];
    _positionLabel.textAlignment = NSTextAlignmentCenter;
    _positionLabel.font = [UIFont systemFontOfSize:13];
    [self updatePositionLabelToSelectedState:NO];

    [self.contentView addSubview:_positionLabel];

    self.selectedBackgroundView = _selectionFrame;

    CGFloat labelTextSize = 12.0;
    CGFloat labelHeight = 30.0;
    CGColorRef topGradientColor = [[UIColor colorWithWhite:0 alpha:0] CGColor];
    CGColorRef bottomGradientColor = [[UIColor colorWithWhite:0 alpha:0.5] CGColor];

    _gradientView = [[UIView alloc] initWithFrame:CGRectMake(0, self.contentView.frame.size.height - labelHeight, self.contentView.frame.size.width, labelHeight)];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = _gradientView.bounds;
    gradient.colors = @[(__bridge id)topGradientColor, (__bridge id)(bottomGradientColor)];
    [_gradientView.layer addSublayer:gradient];
    _gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _gradientView.hidden = YES;
    [self.backgroundView addSubview:_gradientView];

    _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelMargin, self.contentView.frame.size.height - (labelMargin), self.contentView.frame.size.width - (2*labelMargin), - labelTextSize)];
    _captionLabel.backgroundColor = [UIColor clearColor];
    _captionLabel.hidden = YES;
    _captionLabel.textColor = [UIColor whiteColor];
    _captionLabel.textAlignment = NSTextAlignmentRight;
    _captionLabel.font = [UIFont boldSystemFontOfSize:labelTextSize];
    _captionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
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

- (void)configureAccessibility
{
    NSString *accessibilityLabel = @"";
    NSString *formattedDate = NSLocalizedString(@"Unknown creation date", @"Label to use when creation date from media asset is not know.");
    NSDate *assetDate = _asset.date;
    if (assetDate) {
        formattedDate = [NSString stringWithFormat:@"%@ %@",[WPDateTimeHelpers userFriendlyStringDateFromDate:assetDate], [WPDateTimeHelpers userFriendlyStringTimeFromDate:assetDate]];
    }

    switch (self.asset.assetType) {
        case WPMediaTypeImage:
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Image, %@", @"Accessibility label for image thumbnails in the media collection view. The parameter is the creation date of the image."), formattedDate];
            break;
        case WPMediaTypeVideo:
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Video, %@", @"Accessibility label for video thumbnails in the media collection view. The parameter is the creation date of the video."), formattedDate];
            break;
        case WPMediaTypeAudio:
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Audio, %@", @"Accessibility label for audio items in the media collection view. The parameter is the creation date of the audio."), formattedDate];
            break;
        case WPMediaTypeOther:
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Document: %@", @"Accessibility label for other media items in the media collection view. The parameter is the filename file."), [_asset filename]];
            break;
        default:
            break;
    }
    self.accessibilityLabel = accessibilityLabel;
    self.accessibilityHint = NSLocalizedString(@"Select media.", @"Accessibility hint for actions when displaying media items.");
}

- (void)displayAssetTypePlaceholder
{
    self.placeholderStackView.hidden = NO;
    self.imageView.hidden = YES;
    UIImage * iconImage = nil;
    NSString *caption = nil;
    NSString *extension = nil;
    if ([self.asset respondsToSelector:@selector(filename)]) {
        caption = [self.asset filename];
    }

    switch (self.asset.assetType) {
        case WPMediaTypeImage:
            iconImage = [WPMediaPickerResources imageNamed:@"gridicons-camera" withExtension:@"png"];
            extension = NSLocalizedString(@"IMAGE", @"Label displayed on audio media items.");
            caption = nil;
            break;
        case WPMediaTypeVideo:
            iconImage = [WPMediaPickerResources imageNamed:@"gridicons-video-camera" withExtension:@"png"];
            extension = NSLocalizedString(@"VIDEO", @"Label displayed on audio media items.");
            caption = [WPDateTimeHelpers stringFromTimeInterval:[self.asset duration]];
            break;
        case WPMediaTypeAudio:
            iconImage = [WPMediaPickerResources imageNamed:@"gridicons-audio" withExtension:@"png"];
            extension = NSLocalizedString(@"AUDIO", @"Label displayed on audio media items.");
            caption = [WPDateTimeHelpers stringFromTimeInterval:[self.asset duration]];
            break;
        case WPMediaTypeOther:
            iconImage = [WPMediaPickerResources imageNamed:@"gridicons-pages" withExtension:@"png"];
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
}

- (void)setAsset:(id<WPMediaAsset>)asset {
    _asset = asset;
    [self configureAccessibility];
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

- (void)updateCellWithImage:(UIImage *)image error:(NSError *)error timestamp:(NSTimeInterval)timestamp requestKey:(WPMediaRequestID)requestKey{
    if (error || image == nil) {
        [self displayAssetTypePlaceholder];
        return;
    }
    // Did this request changed meanwhile
    if (requestKey != self.requestKey) {
        return;
    }
    if (_asset.assetType == WPMediaTypeVideo || _asset.assetType == WPMediaTypeAudio) {
        NSString *caption = [WPDateTimeHelpers stringFromTimeInterval:[self.asset duration]];
        [self setCaption:caption];
    }
    self.imageView.hidden = NO;
    self.placeholderStackView.hidden = YES;
    BOOL animated = ([NSDate timeIntervalSinceReferenceDate] - timestamp) > ThresholdForAnimation;
    [self setImage:image
          animated:animated];
}

- (void)fetchAssetImage
{
    __block WPMediaRequestID requestKey = 0;
    NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize requestSize = CGSizeApplyAffineTransform(self.frame.size, CGAffineTransformMakeScale(scale, scale));
    __weak __typeof__(self) weakSelf = self;
    requestKey = [_asset imageWithSize:requestSize completionHandler:^(UIImage *result, NSError *error) {
        if ([NSThread isMainThread]){
            [weakSelf updateCellWithImage:result error:error timestamp:timestamp requestKey:requestKey];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateCellWithImage:result error:error timestamp:timestamp requestKey:requestKey];
            });
        }
    }];
    self.requestKey = requestKey;
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
    if (position != NSNotFound) {
        self.positionLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)(position)];
    } else {
        self.positionLabel.text = @"";
    }
}

- (void)setCaption:(NSString *)caption
{
    BOOL hide = caption.length <= 0;
    self.captionLabel.hidden = hide;
    self.gradientView.hidden = hide;
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
    if (selected == self.isSelected) {
        return;
    }
    [super setSelected:selected];
    [self updatePositionLabelToSelectedState:self.isSelected];
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    _selectionFrame.layer.borderColor = [[self tintColor] CGColor];

    [self updatePositionLabelToSelectedState:self.isSelected];
}

- (void)updatePositionLabelToSelectedState:(BOOL)selected
{
    if (selected) {
        _positionLabel.backgroundColor = [self tintColor];
        _positionLabel.layer.borderColor = [self tintColor].CGColor;
        _positionLabel.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
        _positionLabel.layer.shadowRadius = 10.0;
        _positionLabel.layer.shadowOffset = CGSizeMake(10, 10);
    } else {
        _positionLabel.text = @"";
        _positionLabel.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
        _positionLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    }

}

@end
