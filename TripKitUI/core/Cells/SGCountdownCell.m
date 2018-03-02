//
//  SGCountdownCell.m
//  TripKit
//
//  Created by Adrian Schoenig on 19/02/2014.
//
//

#import "SGCountdownCell.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#import "TripKitUI/TripKitUI-Swift.h"
#endif

#import "SGStyleManager+SGCoreUI.h"

typedef enum {
	SGCountdownColorNeutral,
	SGCountdownColorGreen,
	SGCountdownColorRed,
} SGCountdownColor;

@interface SGCountdownCell ()

@property (nonatomic, strong) NSDate *time;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) SGKGrouping position;

@property (weak, nonatomic) IBOutlet UIView *contentWrapper;

// Interface outlets - Main view
@property (nonatomic, weak) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLeadingSpace;

// Main view: counting down
@property (nonatomic, weak) IBOutlet UIView *timeWrapper;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timeWrapperWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *timeWrapperLeadingSpace;

@end

@implementation SGCountdownCell

#pragma mark - Custom accessors

- (BOOL)showTickIcon
{
  return ! self.tickView.hidden;
}

- (void)setShowTickIcon:(BOOL)showTickIcon
{
  self.tickView.hidden = ! showTickIcon;
  
  if (showTickIcon) {
    self.accessibilityTraits |= UIAccessibilityTraitSelected;
  } else {
    self.accessibilityTraits &= ~UIAccessibilityTraitSelected;
  }
}

- (BOOL)showAlertIcon
{
  return ! self.alertIcon.hidden;
}

- (void)setShowAlertIcon:(BOOL)showAlertIcon
{
  self.alertIcon.hidden = ! showAlertIcon;
}

#pragma mark - UITableViewCell

- (void)awakeFromNib
{
  [super awakeFromNib];
  
  self.objcDisposeBag = [[SGObjCDisposeBag alloc] init];

  // This property can be set via appearance proxy. If not set, we'd use
  // the root tint color.
  _preferredTintColor = self.tintColor;
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  
  [self _resetContents];
  
  self.contentWrapperTopConstraint.constant = 0;
  self.contentWrapperBottomConstraint.constant = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [self setHighlighted:selected animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
  [UIView animateWithDuration:animated ? 0.25f : 0
                   animations:
   ^{
     self.contentWrapper.backgroundColor = highlighted ? [SGStyleManager cellSelectionBackgroundColor] : [UIColor whiteColor];
   }];
}

- (void)updateConstraints
{  
  BOOL requireAccessibility = self.accessibleLabel.text.length != 0;
  self.accessibleIconWidth.constant = requireAccessibility ? 20 : 0;
  self.accessibleTopConstraint.constant = requireAccessibility ? 8 : 0;
  self.accessibleBottomConstraint.constant = requireAccessibility ? 8 : 0;

  if (! self.modeIcon.image) {
    self.iconWidth.constant = 0.0f;
    self.titleLeadingSpace.constant = 0.0f;
  } else {
    self.iconWidth.constant = 30.0f;
    self.titleLeadingSpace.constant = 8.0f;
  }
  
  if (self.time == nil) {
    self.timeWrapperWidth.constant = 0.0f;
    self.timeWrapperLeadingSpace.constant = 0.0f;
    self.timeWrapper.layoutMargins = UIEdgeInsetsZero;
  } else {
    self.timeWrapperWidth.constant = 64.0f;
    self.timeWrapperLeadingSpace.constant = 8.0f;
    self.timeWrapper.layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8);
  }
  
  [self adjustContentWrapperWithBasedOn:self.position];
  
  [super updateConstraints];
}

#pragma mark - Private: Configuration

- (void)_configureWithTitle:(NSAttributedString *)title
                   subtitle:(NSString *)subtitle
                subsubtitle:(NSString *)subsubtitle
                       icon:(UIImage *)icon
               iconImageURL:(NSURL *)iconImageURL
          timeToCountdownTo:(NSDate *)time
                   position:(SGKGrouping)position
                 stripColor:(UIColor *)stripColor
{
  self.preservesSuperviewLayoutMargins = NO;
  self.contentView.preservesSuperviewLayoutMargins = NO;
  
  self.time = time;
  self.position = position;
  
  [self.modeIcon setImageWithURL:iconImageURL placeholderImage:icon];
  self.modeIcon.tintColor = [SGStyleManager darkTextColor];
  
  self.title.attributedText = title;
  self.subtitle.text = subtitle;
  self.subsubTitle.text = subsubtitle;
  
  self.coloredStrip.backgroundColor = stripColor;
  
  // time.
  if (time == nil) {
    self.timeLetterLabel.text = nil;
    self.timeNumberLabel.text = nil;
    self.timeWrapper.hidden = YES;
  } else {
    self.timeWrapper.hidden = NO;
    self.timeWrapper.layer.cornerRadius = 3.0f;
    [self updateTimeView:YES];
  }

  if (position == SGKGrouping_EdgeToEdge) {
    self.backgroundColor = self.contentWrapper.backgroundColor;
  }
  
  if (position != SGKGrouping_EdgeToEdge) {
    [SGStyleManager addDefaultOutline:self.contentWrapper];
  }
}

#pragma mark - Private: Time wrapper stuff

- (UIColor *)redColor
{
	return [UIColor colorWithRed:231/255.0f green:77/255.0f blue:79/255.0f alpha:1.f];
}

- (UIColor *)strongGreenColor
{
  return [SGStyleManager globalTintColor];
}

- (UIColor *)subtleGreenColor
{
  return [SGStyleManager globalTintColor];
}

- (UIColor *)neutralColor
{
	return [UIColor colorWithWhite:183/255.0f alpha:1.f];
}

- (NSInteger)minutesToShow
{
  return (NSInteger) [self.time timeIntervalSinceNow] / 60;
}

- (BOOL)roundUpMinutes
{
  return YES;
}

- (BOOL)fadeOnTimeOut
{
	return YES;
}

- (BOOL)countdown
{
  return YES;
}

- (NSInteger)fuzzifiedMinutes:(NSInteger)minutes
{
	if (minutes < 0)
		return (NSInteger) floor(minutes);
	else if (minutes < 2)
		return 0;
	else if (minutes < 10)
		return minutes;
	else if (minutes < 20)
		return minutes / 2 * 2;
	else
		return minutes / 5 * 5;
}

- (void)setTimeLetter:(NSString *)letterOrNil
{
  self.timeWrapper.alpha = 1;
	self.timeWrapper.hidden = NO;
  self.timeLetterLabel.text = letterOrNil;
	
	if (letterOrNil != nil) {
		self.timeLetterLabel.hidden = NO;
		self.timeNumberLabel.hidden = YES;
    self.timeNumberLabel.text = nil;
		
	} else {
		self.timeNumberLabel.hidden = NO;
		self.timeLetterLabel.hidden = YES;
    self.timeLetterLabel.text = nil;
	}
	
	// make sure the alpha is ok
	[self adjustTimeLabelAlpha];
}

- (void)setTimeLetter:(NSString *)letterOrNil color:(SGCountdownColor)color
{
	[self setTimeLetter:letterOrNil];
	
	switch (color) {
		case SGCountdownColorGreen:
			self.timeWrapper.backgroundColor = [self strongGreenColor];
			break;
			
		case SGCountdownColorNeutral:
			self.timeWrapper.backgroundColor = [self neutralColor];
			break;
      
		case SGCountdownColorRed:
			self.timeWrapper.backgroundColor = [self redColor];
			break;
	}
}

- (void)setFaded:(BOOL)faded animated:(BOOL)animated
{
	if (faded) {
		[self.timer invalidate];
		self.timer = nil;
	}
  
	[UIView animateWithDuration:animated ? 0.25 : 0
									 animations:
	 ^{
		 self.mainView.alpha = faded ? 0.5f : 1;
	 }];
}

- (void)updateTimeView:(BOOL)animated
{
  // hide the wrapper
	if (self.time == nil) {
		return;
	}
	
	// show minutes, hours, days, etc...
	NSInteger minutes = [self minutesToShow];
  BOOL isInFuture = minutes >= 0;
  NSTimeInterval absoluteMinutes = minutes * (isInFuture ? 1 : -1);
  
  NSString *durationString = nil;
	if (absoluteMinutes < 60) { // less than an hour
		if ([self roundUpMinutes]) {
			minutes = [self fuzzifiedMinutes:minutes];
		}
    durationString = [SGKObjcDateHelper durationStringForMinutes:minutes];
	} else if (absoluteMinutes < 1440) { // less than a day
		NSInteger hours = (NSInteger) (minutes / 60);
    durationString = [SGKObjcDateHelper durationStringForHours:hours];
 	} else { // days
		NSInteger days = (NSInteger) (minutes / 1440);
    durationString = [SGKObjcDateHelper durationStringForDays:days];
	}
  
  if (self.showAsCanceled) {
    [self setTimeLetter:Loc.Cancelled color:SGCountdownColorRed];
  } else if (minutes == 0) {
		[self setTimeLetter:Loc.Now];
	} else {
		[self setTimeLetter:nil];
		self.timeNumberLabel.text = durationString;
    if (isInFuture) {
      self.timeNumberLabel.accessibilityLabel = [Loc InDurationString:durationString];
    } else {
      self.timeNumberLabel.accessibilityLabel = [Loc AgoDurationString:durationString];
    }
	}
	
  if (! self.showAsCanceled) {
    // set the background colour
    [UIView animateWithDuration:animated ? 0.25 : 0
                     animations:
     ^{
       self.timeWrapper.backgroundColor = [self timeToBackgroundColor];
     }];
  }
	
	if ([self fadeOnTimeOut]) {
		BOOL hide = !isInFuture;
		[self setFaded:hide animated:animated];
	}
	
	// update every 5 seconds
	if ([self countdown]) {
		[self.timer invalidate];
		self.timer = [NSTimer scheduledTimerWithTimeInterval:5
																									target:self
																								selector:@selector(updateTimeViewAnimated)
																								userInfo:nil
																								 repeats:NO];
	}
}

- (void)updateTimeViewAnimated
{
	if (nil == self.superview) {
		return; // don't update anymore
	}
	
	[self updateTimeView:YES];
}

/**
 * Determines the background colour for the time label, based on how far from
 * now 'departureTime' is. It's the default if it's more than 5 minutes away,
 * then it starts converging to a reddish colour.
 */
- (UIColor *)timeToBackgroundColor
{
	if (self.time == nil)
		return [self neutralColor];
	
	NSInteger minutes = (NSInteger) ([self.time timeIntervalSinceNow] / 60);
	
#define TIME_TO_START_HIGLIGHTING 15.0f
	
	if (minutes < 0) {
		return [self neutralColor];
    
  } else if (minutes > TIME_TO_START_HIGLIGHTING) {
    return [self subtleGreenColor];

	} else {
    UIColor *fadeFrom = [self subtleGreenColor];
    
		CGFloat redFrom, greenFrom, blueFrom, alpha;
		[fadeFrom getRed:&redFrom green:&greenFrom blue:&blueFrom alpha:&alpha];
		
		UIColor *fadeTo = [self strongGreenColor];
		CGFloat redTo, greenTo, blueTo;
		[fadeTo getRed:&redTo green:&greenTo blue:&blueTo alpha:&alpha];
    
		
		CGFloat danger = (TIME_TO_START_HIGLIGHTING - minutes) / TIME_TO_START_HIGLIGHTING;
		CGFloat red   = redTo		+ (redFrom - redTo)   * (1 - danger);
		CGFloat green = greenTo + (greenFrom - greenTo) * (1 - danger);
		CGFloat blue  = blueTo  + (blueFrom - blueTo)  * (1 - danger);
		return [UIColor colorWithRed:red
													 green:green
														blue:blue
													 alpha:alpha];
	}
}

- (void)adjustTimeLabelAlpha
{
	self.timeWrapper.alpha = self.isEditing ? 0 : (nil != self.timeWrapper ? 1 : 0);
}

#pragma mark - Private: Content reset

- (void)_resetContents
{
  self.objcDisposeBag = [[SGObjCDisposeBag alloc] init];
  
  self.coloredStrip.backgroundColor = nil;
  
  self.footnoteView.hidden = YES;
  self.centerMainStack.spacing = 0.0f;
  [self.footnoteView removeAllSubviews];
  
  [self resetLabels];
  [self resetImageViews];
  
  self.accessibleSeparator.hidden = YES;
  self.alertSeparator.hidden = YES;
  
  [self.timer invalidate];
  self.timer = nil;
}

- (void)resetLabels
{
  [self resetLabel:self.title];
  [self resetLabel:self.subtitle];
  [self resetLabel:self.subsubTitle];
  [self resetLabel:self.alertLabel];
  [self resetLabel:self.timeLetterLabel];
  [self resetLabel:self.timeNumberLabel];
  [self resetLabel:self.accessibleLabel];
}

- (void)resetImageViews
{
  [self resetImageView:self.modeIcon];
  [self resetImageView:self.alertSymbol];
  [self resetImageView:self.alertIcon];
  [self resetImageView:self.tickView];
  [self resetImageView:self.accessibleIcon];
}

- (void)resetLabel:(UILabel *)label
{
  label.text = nil;
}

- (void)resetImageView:(UIImageView *)imageView
{
  imageView.image = nil;
}

@end
