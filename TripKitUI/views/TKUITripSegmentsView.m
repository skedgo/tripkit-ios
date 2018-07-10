//
//  TKUITripSegmentsView.m
//  TripKit
//
//  Created by Adrian Schoenig on 20/01/2014.
//
//

#import "TKUITripSegmentsView.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#import "TripKitUI/TripKitUI-Swift.h"
#endif


#import "TKUIStyledLabel.h"
#import "UIColor+Variations.h"
#import "TKStyleManager+TripKitUI.h"
#import "UIView+Helpers.h"

#define SEGMENT_ITEM_ALPHA 1
#define SEGMENT_ITEM_ALPHA_PAST 0.25

@interface TKUITripSegmentsView ()

@property (nonatomic, assign) CGSize desiredSize;
@property (nonatomic, assign) BOOL centerSegments;

@property (nonatomic, assign) BOOL didLayoutSubviews;
@property (nonatomic, nullable, strong) void (^onLayoutSubviews)(void);

@end

@implementation TKUITripSegmentsView

- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self didInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self didInit];
  }
  return self;
}

- (void)didInit {
  self.darkTextColor = [TKStyleManager darkTextColor];
  self.lightTextColor = [TKStyleManager lightTextColor];
}

- (CGSize)intrinsicContentSize
{
  return self.desiredSize;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  self.didLayoutSubviews = YES;
  if (self.onLayoutSubviews != nil) {
    self.onLayoutSubviews();
    self.onLayoutSubviews = nil;
  }
}

- (void)configureForSegments:(NSArray<id<TKTripSegmentDisplayable>> *)segments
              allowSubtitles:(BOOL)allowSubtitles
              allowInfoIcons:(BOOL)allowInfoIcons
{
  [self configureForSegments:segments allowTitles:allowSubtitles allowSubtitles:allowSubtitles allowInfoIcons:allowInfoIcons];
}

- (void)configureForSegments:(NSArray<id<TKTripSegmentDisplayable>> *)segments
                 allowTitles:(BOOL)allowTitles
              allowSubtitles:(BOOL)allowSubtitles
              allowInfoIcons:(BOOL)allowInfoIcons
{
  if (!self.didLayoutSubviews) {
    // When calling `configureForSegments` before `layoutSubviews` was called
    // the frame information of this view is most likely not yet what it'll
    // be before this view will be visible, so we'll delay configuring this view
    // until after `layoutSubviews` was called.
    __weak typeof(self) weakSelf = self;
    self.onLayoutSubviews = ^(){
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf configureForSegments:segments allowTitles:allowTitles allowSubtitles:allowSubtitles allowInfoIcons:allowInfoIcons];
    };
    return;
  }
  
  // clean up cells
  [self removeAllSubviews];
	
#define PADDING 12
  CGFloat padding = PADDING * (self.tiny ? 0.6f : 1.0f);
  CGFloat nextX = padding / 2;
  
  // populate scroll view with segments
  int count = 0;
	NSInteger segmentCount = segments.count;
	
  CGFloat widthPerSegment = (self.frame.size.width - nextX) / segmentCount;
	
  if (self.centerSegments && widthPerSegment > 34) {
    self.centerSegments = false; // looks weird otherwise
  }
  
  for (id<TKTripSegmentDisplayable> segment in segments) {
    
		UIViewAutoresizing mask = 0;
    
    // create image view
    UIImage *image = [segment tripSegmentModeImage];
		if (! image) {
      // this can happen if a trip was visible while TripKit got cleared
			continue;
		}
		
		// for the coloured strip
    UIColor *color = [segment respondsToSelector:@selector(tripSegmentModeColor)] ? [segment tripSegmentModeColor] : nil;
		
		// the mode image
    UIImageView * modeImageView = [[UIImageView alloc] initWithImage:image];
    modeImageView.alpha = SEGMENT_ITEM_ALPHA;
    
    if (self.colorCodingTransitIcon) {
      // remember that color will be nil for non-PT modes. In these cases, since the
      // PT mode will be colored, we use the lighter grey to reduce the contrast.
      modeImageView.tintColor = color ?: self.lightTextColor;
    } else {
      modeImageView.tintColor = self.darkTextColor;
    }

    NSURL *modeImageURL = [segment tripSegmentModeImageURL];
    BOOL asTemplate = [segment tripSegmentModeImageIsTemplate];
    if (modeImageURL) {
      [modeImageView setImageWithURL:modeImageURL asTemplate:asTemplate placeholderImage:image];
    }
    
    // place the mode image
    CGFloat imageWidth = image.size.width * (self.tiny ? 0.6f : 1.0f);
    CGFloat imageHeight = image.size.height * (self.tiny ? 0.6f : 1.0f);
    CGRect newFrame = modeImageView.frame;
    if (self.centerSegments) {
			if (count == 0) {
				mask = UIViewAutoresizingFlexibleRightMargin;
			} else if (count == segmentCount - 1) {
				mask = UIViewAutoresizingFlexibleLeftMargin;
			} else {
				mask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			}
      newFrame.origin.x = count * widthPerSegment + (widthPerSegment - imageWidth) / 2;
    } else {
      newFrame.origin.x = nextX;
    }
    
    newFrame.origin.y = (self.frame.size.height - imageHeight) / 2;
    newFrame.size.width = imageWidth;
    newFrame.size.height = imageHeight;
		modeImageView.autoresizingMask = mask;
    modeImageView.frame = newFrame;
    [self addSubview:modeImageView];
		
		if (allowInfoIcons && [segment respondsToSelector:@selector(tripSegmentModeInfoIconType)]
        && [segment tripSegmentModeInfoIconType] != TKInfoIconTypeNone) {
			UIImageView *infoIconImageView = [[UIImageView alloc] initWithImage:[TKInfoIcon imageForInfoIconType:[segment tripSegmentModeInfoIconType] usage:TKInfoIconUsageOverlay]];
      CGRect imageFrame = infoIconImageView.frame;
      imageFrame.origin.x = newFrame.origin.x;
      imageFrame.origin.y = newFrame.origin.y + CGRectGetHeight(newFrame) - CGRectGetHeight(imageFrame);
			infoIconImageView.frame = imageFrame;
			infoIconImageView.autoresizingMask = mask;
			[self addSubview:infoIconImageView];
		}
		
    CGFloat modeSideWidth = 0;
    // we put mode codes, colours and subtitles to the side
    // subtitle, we are allowed to
    
    CGFloat x = CGRectGetMaxX(newFrame);
    CGSize  modeTitleSize  = CGSizeZero;
    CGSize  modeSubtitleSize = CGSizeZero;
    
    UIFont *modeTitleFont = nil;
    UIFont *modeSubtitleFont = nil;
    
    NSString *modeTitle = (allowTitles && [segment respondsToSelector:@selector(tripSegmentModeTitle)]) ? [segment tripSegmentModeTitle] : nil;
    if (modeTitle.length > 0) {
      modeTitleFont = [TKStyleManager systemFontWithSize:12];
      modeTitleSize = [modeTitle sizeWithFont:modeTitleFont
                           maximumWidth:CGFLOAT_MAX];
    } else if (color) {
      modeTitleSize = CGSizeMake(10, 10);
    }
    
    UIImageView *modeTitleAccessoryImageView = nil;
    if (allowTitles
        && self.allowWheelchairIcon
        && [segment respondsToSelector:@selector(tripSegmentIsWheelchairAccessible)]
        && [segment tripSegmentIsWheelchairAccessible]) {
      modeTitleAccessoryImageView = [[UIImageView alloc] initAsWheelchairAccessoryImageWithTintColor:[TKStyleManager darkTextColor]];
    }
    
    
    // We prefer the time + real-time indicator as the subtitle, and fall back
    // to the subtitle
    NSString *modeSubtitle = nil;
    UIImageView *modeSubtitleAccessoryImageView = nil;
    if (allowSubtitles) {
      if ([segment respondsToSelector:@selector(tripSegmentFixedDepartureTime)]) {
        modeSubtitle = [TKStyleManager timeString:[segment tripSegmentFixedDepartureTime]
                                      forTimeZone:[segment tripSegmentTimeZone]];

        if ([segment respondsToSelector:@selector(tripSegmentTimesAreRealTime)]
            && [segment tripSegmentTimesAreRealTime]) {
          modeSubtitleAccessoryImageView = [[UIImageView alloc] initAsRealTimeAccessoryImageAnimated:YES tintColor:[TKStyleManager lightTextColor]];
        }
      }
      if (! modeSubtitle && [segment respondsToSelector:@selector(tripSegmentModeSubtitle)]) {
        modeSubtitle = [segment tripSegmentModeSubtitle];
      }
      if (modeSubtitle) {
        modeSubtitleFont = [TKStyleManager systemFontWithSize:10];
        modeSubtitleSize = [modeSubtitle sizeWithFont:modeSubtitleFont maximumWidth:CGFLOAT_MAX];
      }
    }
    
    if (modeTitle.length > 0) {
      // add the bus number to the side
      CGFloat y = (CGRectGetHeight(self.frame) - modeSubtitleSize.height - modeTitleSize.height) / 2;
      if (modeSubtitleSize.height > 0 || modeSubtitleAccessoryImageView) {
        y += 2;
      }
      
      CGRect rect = CGRectMake(x + 2, y, modeTitleSize.width, modeTitleSize.height);
      TKUIStyledLabel *titleLabel = [[TKUIStyledLabel alloc] initWithFrame:rect];
      titleLabel.font = modeTitleFont;
      titleLabel.text = modeTitle;
      titleLabel.textColor = self.colorCodingTransitIcon ? self.lightTextColor : self.darkTextColor;
      titleLabel.alpha = modeImageView.alpha;
      [self addSubview:titleLabel];
      
      modeSideWidth = (CGFloat) fmax(modeSideWidth, modeTitleSize.width);
    } else if (color && allowSubtitles) {
      // add the color underneath
      CGFloat y = (CGRectGetHeight(self.frame) - modeSubtitleSize.height - modeTitleSize.height) / 2;
      UIView *stripe = [[UIView alloc] initWithFrame:CGRectMake(x, y, modeTitleSize.width, modeTitleSize.height)];
      stripe.layer.borderColor  = color.CGColor;
      stripe.layer.borderWidth  = modeTitleSize.width / 4;
      stripe.layer.cornerRadius = modeTitleSize.width / 2;
      [self addSubview:stripe];
      modeSideWidth = (CGFloat) fmax(modeSideWidth, modeTitleSize.width);
    }
    if (modeTitleAccessoryImageView) {
      CGSize imageSize = modeTitleAccessoryImageView.image.size;
      CGFloat viewWidth;
      CGFloat viewHeight;
      if (modeTitleSize.height > 0) {
        viewHeight = MIN(imageSize.height, modeTitleSize.height);
      } else {
        viewHeight = MIN(imageSize.height, 20);
      }
      viewWidth = viewHeight * (imageSize.width / imageSize.height);
      
      CGFloat y = (CGRectGetHeight(self.frame) - modeSubtitleSize.height - viewHeight) / 2;
      if (modeSubtitleSize.height > 0 || modeSubtitleAccessoryImageView) {
        y += 2;
      }
      
      modeTitleAccessoryImageView.frame = CGRectMake(x + modeTitleSize.width + 2, y, viewWidth, viewHeight);
      [self addSubview:modeTitleAccessoryImageView];
      modeSideWidth = (CGFloat) fmax(modeSideWidth, modeTitleSize.width + 2 + viewWidth);
    }
    
    
    if (modeSubtitle.length > 0) {
      // label goes under the mode code (if we have one)
      CGFloat y = (CGRectGetHeight(self.frame) - modeSubtitleSize.height - modeTitleSize.height) / 2 + modeTitleSize.height;
      
      CGRect rect = CGRectMake(x + 2, y, modeSubtitleSize.width, modeSubtitleSize.height);
      TKUIStyledLabel *subtitleLabel = [[TKUIStyledLabel alloc] initWithFrame:rect];
      subtitleLabel.font = modeSubtitleFont;
      subtitleLabel.text = modeSubtitle;
      subtitleLabel.textColor = [TKStyleManager lightTextColor];
      subtitleLabel.alpha = modeImageView.alpha;
      [self addSubview:subtitleLabel];
      
      modeSideWidth = (CGFloat) fmax(modeSideWidth, modeSubtitleSize.width);
    }
    if (modeSubtitleAccessoryImageView) {
      CGSize imageSize = modeSubtitleAccessoryImageView.image.size;
      CGFloat viewWidth;
      CGFloat viewHeight;
      if (modeSubtitleSize.height > 0) {
        viewHeight = MIN(imageSize.height, modeSubtitleSize.height);
      } else {
        viewHeight = MIN(imageSize.height, 20);
      }
      viewWidth = viewHeight * (imageSize.width / imageSize.height);
      
      CGFloat y = (CGRectGetHeight(self.frame) - viewHeight - modeTitleSize.height) / 2 + modeTitleSize.height;

      modeSubtitleAccessoryImageView.frame = CGRectMake(x + modeSubtitleSize.width + 2, y, viewWidth, viewHeight);
      [self addSubview:modeSubtitleAccessoryImageView];
      modeSideWidth = (CGFloat) fmax(modeSideWidth, modeSubtitleSize.width + 2 + viewWidth);
    }
      
    nextX = CGRectGetMaxX(newFrame) + modeSideWidth + padding;
    count++;
    if (allowSubtitles) {
      self.desiredSize = CGSizeMake(nextX, self.frame.size.height);
    }
    
    if (nextX > CGRectGetWidth(self.frame)) {
      // can we shrink?
      if (allowSubtitles) {
        [self configureForSegments:segments
                       allowTitles:allowTitles
                    allowSubtitles:NO
                    allowInfoIcons:allowInfoIcons];
        return;
      
      } else if (allowTitles) {
        [self configureForSegments:segments
                       allowTitles:NO
                    allowSubtitles:NO
                    allowInfoIcons:allowInfoIcons];
        return;
      }
    }
  }
}


#pragma mark - Private helpers

- (UIColor *)colorForBackground:(UIColor *)backgroundColor withDefault:(UIColor *)defaultColor
{
	if ([defaultColor isDark]) {
		if ([backgroundColor isDark]) {
			return [UIColor whiteColor];
		} else {
			return defaultColor;
		}
	} else {
		if ([backgroundColor isDark]) {
			return defaultColor;
		} else {
			return [UIColor blackColor];
		}
	}
}


@end
