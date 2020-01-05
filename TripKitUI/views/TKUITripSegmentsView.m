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

#define SEGMENT_ITEM_ALPHA_SELECTED   1
#define SEGMENT_ITEM_ALPHA_DESELECTED 0.25

@implementation NSString (Sizing)

- (CGSize)sizeWithFont:(TKFont *)font maximumWidth:(CGFloat)maxWidth
{
  NSDictionary *atts = @{NSFontAttributeName: font};
  NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
  context.minimumScaleFactor = 1;
  CGRect box = [self boundingRectWithSize:CGSizeMake(maxWidth, 0)
                                  options:NSStringDrawingUsesLineFragmentOrigin
                               attributes:atts
                                  context:context];
  return CGSizeMake((CGFloat) ceil(box.size.width), (CGFloat) ceil(box.size.height));
}

@end

@interface TKUITripSegmentsView ()

@property (nonatomic, assign) CGSize desiredSize;

@property (nonatomic, assign) BOOL didLayoutSubviews;
@property (nonatomic, nullable, strong) void (^onLayoutSubviews)(void);

@property (nonatomic, copy) NSArray<NSNumber *>* segmentXValues;
@property (nonatomic, assign) NSInteger segmentIndexToSelect;

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
  self.darkTextColor = UIColor.tkLabelPrimary;
  self.lightTextColor = UIColor.tkLabelSecondary;
  self.segmentIndexToSelect = -1;
}

- (CGSize)intrinsicContentSize
{
  if (CGSizeEqualToSize(CGSizeZero, self.desiredSize) && self.onLayoutSubviews != nil) {
    self.didLayoutSubviews = YES;
    self.onLayoutSubviews();
    self.onLayoutSubviews = nil;
  }
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
  
  // We might not yet have a frame, if the Auto Layout engine wants to get the
  // intrinsic size of this view, before it's been added. In that case, we
  // let it grow as big as it wants to be.
  BOOL limitSize = !CGSizeEqualToSize(CGSizeZero, self.frame.size);
  CGFloat maxHeight = limitSize ? CGRectGetHeight(self.frame) : 44;
  
  NSMutableArray *segmentXValues = [NSMutableArray arrayWithCapacity:segments.count];
  NSInteger segmentIndexToSelect = (self.segmentIndexToSelect >=0 && self.segmentIndexToSelect < segments.count) ? self.segmentIndexToSelect : -1;
  
  // populate scroll view with segments
  int count = 0;
  
  for (id<TKTripSegmentDisplayable> segment in segments) {

    UIViewAutoresizing mask = 0;
    CGFloat alpha = (segmentIndexToSelect == -1 || segmentIndexToSelect == count) ? SEGMENT_ITEM_ALPHA_SELECTED : SEGMENT_ITEM_ALPHA_DESELECTED;
    
    // create image view
    UIImage *image = [segment tripSegmentModeImage];
		if (! image) {
      // this can happen if a trip was visible while TripKit got cleared
			continue;
		}
		
		// for the coloured strip
    UIColor *color = [segment tripSegmentModeColor];
		
		// the mode image
    UIImageView *modeImageView = [[UIImageView alloc] initWithImage:image];
    modeImageView.alpha = alpha;
    
    if (self.colorCodingTransitIcon) {
      // remember that color will be nil for non-PT modes. In these cases, since the
      // PT mode will be colored, we use the lighter grey to reduce the contrast.
      modeImageView.tintColor = color ?: self.lightTextColor;
    } else {
      modeImageView.tintColor = self.darkTextColor;
    }

    // place the mode image
    CGFloat imageWidth = image.size.width * (self.tiny ? 0.6f : 1.0f);
    CGFloat imageHeight = image.size.height * (self.tiny ? 0.6f : 1.0f);
    CGRect newFrame = modeImageView.frame;
    newFrame.origin.x = nextX;
    [segmentXValues addObject:@(nextX)];
    
    newFrame.origin.y = (maxHeight - imageHeight) / 2;
    newFrame.size.width = imageWidth;
    newFrame.size.height = imageHeight;
		modeImageView.autoresizingMask = mask;
    modeImageView.frame = newFrame;

    UIImageView *brandImageView;
    NSURL *modeImageURL = [segment tripSegmentModeImageURL];
    BOOL asTemplate = [segment tripSegmentModeImageIsTemplate];
    BOOL asBranding = [segment tripSegmentModeImageIsBranding];
    if (modeImageURL) {
      UIView *modeCircleBackground = nil;
      if (!asTemplate) {
        // remote images that aren't templates look weird on the background colour
        CGRect circleFrame = CGRectInset(newFrame, -1.0f, -1.0f);
        modeCircleBackground = [[UIView alloc] initWithFrame:circleFrame];
        modeCircleBackground.backgroundColor = [UIColor whiteColor];
        modeCircleBackground.layer.cornerRadius = CGRectGetWidth(circleFrame) / 2;
        modeCircleBackground.alpha = alpha;
        [self addSubview:modeCircleBackground];
      }
      
      if (asBranding) {
        // brand images are not overlaid over the mode icon, but appear next
        // to them
        CGRect brandFrame = newFrame;
        brandFrame.origin.x += brandFrame.size.width + 2;
        brandImageView = [[UIImageView alloc] initWithFrame:brandFrame];
        brandImageView.autoresizingMask = mask;
        brandImageView.alpha = alpha;
        [brandImageView setImageWithURL:modeImageURL];
        newFrame = brandFrame;
        
      } else {
        [modeImageView setImageWithURL:modeImageURL asTemplate:asTemplate placeholderImage:image completionHandler:^(BOOL succeed) {
          if (!succeed) {
            [modeCircleBackground removeFromSuperview];
          }
        }];
      }
      
      if (!asTemplate) {
        // add a little bit more spacing next to the circle background
        newFrame.origin.x += 2;
      }
    }

    [self addSubview:modeImageView];

    if (brandImageView) {
      [self addSubview:brandImageView];
    }

		if (allowInfoIcons && [segment tripSegmentModeInfoIconType] != TKInfoIconTypeNone) {
			UIImageView *infoIconImageView = [[UIImageView alloc] initWithImage:[TKInfoIcon imageForInfoIconType:[segment tripSegmentModeInfoIconType] usage:TKInfoIconUsageOverlay]];
      CGRect imageFrame = infoIconImageView.frame;
      imageFrame.origin.x = newFrame.origin.x;
      imageFrame.origin.y = newFrame.origin.y + CGRectGetHeight(newFrame) - CGRectGetHeight(imageFrame);
			infoIconImageView.frame = imageFrame;
			infoIconImageView.autoresizingMask = mask;
      infoIconImageView.alpha = modeImageView.alpha;
			[self addSubview:infoIconImageView];
		}
		
    __block CGFloat modeSideWidth = 0;
    // we put mode codes, colours and subtitles to the side
    // subtitle, we are allowed to
    
    CGFloat x = CGRectGetMaxX(newFrame);
    CGSize  modeTitleSize  = CGSizeZero;
    CGSize  modeSubtitleSize = CGSizeZero;
    
    UIFont *modeTitleFont = nil;
    UIFont *modeSubtitleFont = nil;
    
    NSString *modeTitle = allowTitles ? [segment tripSegmentModeTitle] : nil;
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
        && [segment tripSegmentIsWheelchairAccessible]) {
      modeTitleAccessoryImageView = [[UIImageView alloc] initAsWheelchairAccessoryImageWithTintColor:UIColor.tkLabelPrimary];
    }
    
    NSString *modeSubtitle = nil;
    NSMutableArray<UIImageView *> *modeSubtitleAccessoryImageViews = [NSMutableArray arrayWithCapacity:2];
    if (allowSubtitles) {
      // We prefer the time + real-time indicator as the subtitle, and fall back
      // to the subtitle
      NSDate *fixedTime = [segment tripSegmentFixedDepartureTime];
      if (fixedTime) {
        modeSubtitle = [TKStyleManager timeString:fixedTime
                                      forTimeZone:[segment tripSegmentTimeZone]];
      }

      if ([segment tripSegmentTimesAreRealTime]) {
        [modeSubtitleAccessoryImageViews addObject:[[UIImageView alloc] initAsRealTimeAccessoryImageAnimated:YES tintColor:UIColor.tkLabelSecondary]];
      }

      NSString *subtitleText = [segment tripSegmentModeSubtitle];
      if (! modeSubtitle && subtitleText.length > 0) {
        modeSubtitle = subtitleText;
      }
      
      if (modeSubtitle) {
        modeSubtitleFont = [TKStyleManager systemFontWithSize:10];
        modeSubtitleSize = [modeSubtitle sizeWithFont:modeSubtitleFont maximumWidth:CGFLOAT_MAX];
      }
      
      if (allowInfoIcons && [segment tripSegmentSubtitleIconType] != TKInfoIconTypeNone) {
        UIImageView *infoIconImageView = [[UIImageView alloc] initWithImage:[TKInfoIcon imageForInfoIconType:[segment tripSegmentSubtitleIconType] usage:TKInfoIconUsageOverlay]];
        [modeSubtitleAccessoryImageViews addObject:infoIconImageView];
      }
    }
    
    if (modeTitle.length > 0) {
      // add the bus number to the side
      CGFloat y = (maxHeight - modeSubtitleSize.height - modeTitleSize.height) / 2;
      if (modeSubtitleSize.height > 0 || modeSubtitleAccessoryImageViews.count > 0) {
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
      CGFloat y = (maxHeight - modeSubtitleSize.height - modeTitleSize.height) / 2;
      UIView *stripe = [[UIView alloc] initWithFrame:CGRectMake(x, y, modeTitleSize.width, modeTitleSize.height)];
      stripe.layer.borderColor  = color.CGColor;
      stripe.layer.borderWidth  = modeTitleSize.width / 4;
      stripe.layer.cornerRadius = modeTitleSize.width / 2;
      stripe.alpha = modeImageView.alpha;
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
      
      CGFloat y = (maxHeight - modeSubtitleSize.height - viewHeight) / 2;
      if (modeSubtitleSize.height > 0 || modeSubtitleAccessoryImageViews.count > 0) {
        y += 2;
      }
      
      modeTitleAccessoryImageView.frame = CGRectMake(x + modeTitleSize.width + 2, y, viewWidth, viewHeight);
      modeTitleAccessoryImageView.alpha = modeImageView.alpha;
      [self addSubview:modeTitleAccessoryImageView];
      modeSideWidth = (CGFloat) fmax(modeSideWidth, modeTitleSize.width + 2 + viewWidth);
    }
    
    
    if (modeSubtitle.length > 0) {
      // label goes under the mode code (if we have one)
      CGFloat y = (maxHeight - modeSubtitleSize.height - modeTitleSize.height) / 2 + modeTitleSize.height;
      
      CGRect rect = CGRectMake(x + 2, y, modeSubtitleSize.width, modeSubtitleSize.height);
      TKUIStyledLabel *subtitleLabel = [[TKUIStyledLabel alloc] initWithFrame:rect];
      subtitleLabel.font = modeSubtitleFont;
      subtitleLabel.text = modeSubtitle;
      subtitleLabel.textColor = UIColor.tkLabelSecondary;
      subtitleLabel.alpha = modeImageView.alpha;
      [self addSubview:subtitleLabel];
      
      modeSideWidth = (CGFloat) fmax(modeSideWidth, modeSubtitleSize.width);
    }
    if (modeSubtitleAccessoryImageViews.count > 0) {
      __block CGFloat subtitleWidth = modeSubtitleSize.width;
      [modeSubtitleAccessoryImageViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull imageView, NSUInteger idx, BOOL * _Nonnull stop) {
        CGSize imageSize = imageView.image.size;
        CGFloat viewWidth;
        CGFloat viewHeight;
        if (modeSubtitleSize.height > 0) {
          viewHeight = MIN(imageSize.height, modeSubtitleSize.height);
        } else {
          viewHeight = MIN(imageSize.height, 20);
        }
        viewWidth = viewHeight * (imageSize.width / imageSize.height);
        
        CGFloat y = (maxHeight - viewHeight - modeTitleSize.height) / 2 + modeTitleSize.height;
        
        imageView.frame = CGRectMake(x + subtitleWidth + 2, y, viewWidth, viewHeight);
        imageView.alpha = modeImageView.alpha;
        [self addSubview:imageView];
        modeSideWidth = (CGFloat) fmax(modeSideWidth, subtitleWidth + 2 + viewWidth);
        subtitleWidth += 2 + viewWidth;
      }];
    }
      
    nextX = CGRectGetMaxX(newFrame) + modeSideWidth + padding;
    count++;
    if (allowSubtitles) {
      self.desiredSize = CGSizeMake(nextX, maxHeight);
    }
    
    if (limitSize && nextX > CGRectGetWidth(self.frame)) {
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
  
  self.segmentXValues = [segmentXValues copy];
}

- (void)selectSegmentAtIndex:(NSInteger)index
{
  self.segmentIndexToSelect = index;
  if (!self.segmentXValues) {
    return;
  }
  
  CGFloat minXToSelect = self.segmentXValues[index].doubleValue;
  CGFloat maxXToSelect = index + 1 < self.segmentXValues.count ? self.segmentXValues[index + 1].doubleValue : CGFLOAT_MAX;

  for (UIView *subview in self.subviews) {
    CGFloat midX = CGRectGetMidX(subview.frame);
    if (midX >= minXToSelect && midX < maxXToSelect) {
      subview.alpha = SEGMENT_ITEM_ALPHA_SELECTED;
    } else {
      subview.alpha = SEGMENT_ITEM_ALPHA_DESELECTED;
    }
  }
}

- (NSInteger)segmentIndexAtX:(CGFloat)x NS_SWIFT_NAME(segmentIndex(atX:))
{
  if (!self.segmentXValues) {
    return 0;
  }

  __block NSUInteger index = 0;
  [self.segmentXValues enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if (obj.doubleValue > x) {
      *stop = true;
    } else {
      index = idx;
    }
  }];
  return index;
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
