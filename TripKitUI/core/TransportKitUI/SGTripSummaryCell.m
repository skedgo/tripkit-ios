//
//  SGTripSummaryCell.m
//  TripKit
//
//  Created by Adrian Schoenig on 20/01/2014.
//
//

#import "SGTripSummaryCell.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#endif


#import "SGLabel.h"
#import "SGButton.h"
#import "SGStyleManager+SGCoreUI.h"
#import "SGTripSegmentsView.h"

@interface SGTripSummaryCell ()


@property (nonatomic, strong) NSTimeZone *departureTimeZone;
@property (nonatomic, strong) NSTimeZone *arrivalTimeZone;
@property (nonatomic, assign) BOOL durationFirst;
@property (nonatomic, assign) BOOL arriveBefore;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainLabelTrailingConstraint;

@end

@implementation SGTripSummaryCell

@synthesize _trip = __trip;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  
  if (self) {
    [self didInitialize];
  }
  
  return self;
}

- (void)awakeFromNib
{
  [super awakeFromNib];
  
  [self didInitialize];
}

- (void)set_trip:(id<STKTrip>)_trip {
  __trip = _trip;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
  [super setSelected:selected animated:animated];
  
  [UIView animateWithDuration:animated ? 0.25f : 0
                   animations:
   ^{
     self.wrapper.backgroundColor = selected ? [SGStyleManager cellSelectionBackgroundColor] : [UIColor whiteColor];
   }];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
  [super setHighlighted:highlighted animated:animated];
  
  if (! self.isSelected) {
    [UIView animateWithDuration:animated ? 0.25f : 0
                     animations:
     ^{
       self.wrapper.backgroundColor = highlighted ? [SGStyleManager cellSelectionBackgroundColor] : [UIColor whiteColor];
     }];
  }
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  
  self.wrapper.backgroundColor = [UIColor whiteColor];
  self.contentView.layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8);
  
  self._trip = nil;
  
  self.departureTimeZone = nil;
  self.arrivalTimeZone = nil;
  self.durationFirst = NO;
  self.arriveBefore  = NO;
}

- (void)updateConstraints
{
  if (! self.showTickIcon) {
    self.mainLabelTrailingConstraint.constant = 8.0f;
  } else {
    self.mainLabelTrailingConstraint.constant = 25.0f;
  }
  
  [super updateConstraints];
}

#pragma mark - Public methods

+ (UINib *)nib
{
  Class aClass = [self class];
  return [UINib nibWithNibName:NSStringFromClass(aClass)
                        bundle:[NSBundle bundleForClass:aClass]];
}

+ (UINib *)nanoNib
{
  Class aClass = [self class];
  return [UINib nibWithNibName:@"SGTripSummaryNanoCell"
                        bundle:[NSBundle bundleForClass:aClass]];
}

- (void)setPreferNoPaddings:(BOOL)preferNoPaddings
{
  _preferNoPaddings = preferNoPaddings;
  self.contentView.layoutMargins = preferNoPaddings ? UIEdgeInsetsZero : UIEdgeInsetsMake(8, 8, 8, 8);
}

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
  return ! self.alertView.hidden;
}

- (void)setShowAlertIcon:(BOOL)showAlertIcon
{
  self.alertView.hidden = ! showAlertIcon;
}

#pragma mark - User Interaction

- (IBAction)actionButtonPressed:(id)sender
{
  if (self._actionBlock) {
    self._actionBlock(sender);
  }
}

#pragma mark - UIAccessibility

- (NSString *)accessibilityLabel
{
  if (self.showAlertIcon) {
    return [NSString stringWithFormat:@"%@ - %@", self._tripAccessibilityLabel, NSLocalizedStringFromTableInBundle(@"Has reminder", @"Shared", [SGStyleManager bundle], @"Accessibility annotation for trips which have a reminder set.")];
  } else {
    return self._tripAccessibilityLabel;
  }
}

#pragma mark - Private: Others

- (void)didInitialize
{
  [SGStyleManager addDefaultOutline:self.wrapper];
  
  self.preservesSuperviewLayoutMargins = NO;
  self.contentView.preservesSuperviewLayoutMargins = NO;
  
  self.wrapper.layer.cornerRadius = 4.0f;
  
  self.showCosts = YES;
  self._objcDisposeBag = [[SGObjCDisposeBag alloc] init];
  
  [self.actionButton addTarget:self
                        action:@selector(actionButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
  
  _preferredTintColor = self.tintColor;
}

- (void)_addTimeStringForDeparture:(NSDate *)departure
                           arrival:(NSDate *)arrival
                 departureTimeZone:(NSTimeZone *)departureTimeZone
                   arrivalTimeZone:(NSTimeZone *)arrivalTimeZone
                   focusOnDuration:(BOOL)durationFirst
               queryIsArriveBefore:(BOOL)arriveBefore
{
  self.departureTimeZone = departureTimeZone;
  self.arrivalTimeZone = arrivalTimeZone;
  self.durationFirst  = durationFirst;
  self.arriveBefore   = arriveBefore;
  
  [self _updateTimeStringForDeparture:departure arrival:arrival];
}

- (void)_updateTimeStringForDeparture:(NSDate *)departure
                              arrival:(NSDate *)arrival
{
  if (departure == nil || arrival == nil) {
    // can happen if trip just got deleted. in that case, ignore it.
    self.mainLabel.attributedText = nil;
    return;
  }
  
  if (self.simpleTimes) {
    NSString *departureString = [SGStyleManager timeString:departure
                                               forTimeZone:self.departureTimeZone
                                        relativeToTimeZone:self.relativeTimeZone];
    NSString *arrivalString   = [SGStyleManager timeString:arrival
                                               forTimeZone:self.arrivalTimeZone
                                        relativeToTimeZone:self.relativeTimeZone];

    
    NSMutableString *title = [NSMutableString stringWithString:departureString];
    [title appendString:@"\n"];
    [title appendFormat:NSLocalizedStringFromTableInBundle(@"to %@", @"Shared", [SGStyleManager bundle], @"to %date. (old key: DateToFormat)"), arrivalString];
    NSString *nonBreaking = [title stringByReplacingOccurrencesOfString:@" " withString:@"\u00a0"];
    self.mainLabel.text = nonBreaking;
    return;
  }
  
  UIFont *primaryFont = _mainLabel.font;
  UIColor *primaryColor = [SGStyleManager darkTextColor];
  
  UIFont *secondaryFont = _mainLabel.font;
  UIColor *secondaryColor = [SGStyleManager lightTextColor];
  
  NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] init];
  NSString *duration = [SGKObjcDateHelper durationStringForStart:departure end:arrival];
  if (self.durationFirst) {
    [self appendString:duration
          toAttributed:attributed
                  font:primaryFont
       foregroundColor:primaryColor];
    
    NSString *secondaryText;
    if (self.arriveBefore) {
      NSString *timeText = [SGStyleManager timeString:departure
                                          forTimeZone:self.departureTimeZone
                                   relativeToTimeZone:self.arrivalTimeZone];
      NSString *bracketed = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"departs %@", @"Shared", [SGStyleManager bundle], "Estimated time of departure; parameter is time, e.g., 'departs 15:30'"), timeText];
      secondaryText = [NSString stringWithFormat:@" (%@)", bracketed];
    } else {
      NSString *timeText = [SGStyleManager timeString:arrival
                                          forTimeZone:self.arrivalTimeZone
                                   relativeToTimeZone:self.departureTimeZone];
      NSString *bracketed = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"arrives %@", @"Shared", [SGStyleManager bundle], "Estimated time of arrival; parameter is time, e.g., 'arrives 15:30'"), timeText];
      secondaryText = [NSString stringWithFormat:@" (%@)", bracketed];
    }
    
    [self appendString:secondaryText
          toAttributed:attributed
                  font:secondaryFont
       foregroundColor:secondaryColor];
    
  } else {
    [self appendString:[SGStyleManager timeString:departure
                                      forTimeZone:self.departureTimeZone
                               relativeToTimeZone:self.arrivalTimeZone]
          toAttributed:attributed
                  font:primaryFont
       foregroundColor:primaryColor];
    
    [self appendString:@" - "
          toAttributed:attributed
                  font:primaryFont
       foregroundColor:primaryColor];
    
    [self appendString:[SGStyleManager timeString:arrival
                                      forTimeZone:self.arrivalTimeZone
                               relativeToTimeZone:self.departureTimeZone]
          toAttributed:attributed
                  font:primaryFont
       foregroundColor:primaryColor];
    
    [self appendString:@" ("
          toAttributed:attributed
                  font:secondaryFont
       foregroundColor:secondaryColor];
    
    [self appendString:duration
          toAttributed:attributed
                  font:secondaryFont
       foregroundColor:secondaryColor];
    
    [self appendString:@")"
          toAttributed:attributed
                  font:secondaryFont
       foregroundColor:secondaryColor];
  }
  
  self.mainLabel.attributedText = attributed;
}

- (void)_addCosts:(NSDictionary *)costDict
{
  NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] init];
  
  NSString *price = costDict[@(STKTripCostTypePrice)];
  if (price) {
    [self appendString:price
          toAttributed:attributed
                  font:nil
       foregroundColor:nil];
    
    [self appendString:@" ⋅ "
          toAttributed:attributed
                  font:nil
       foregroundColor:self.costsLabel.textColor];
  }

  // calories
  [self appendString:costDict[@(STKTripCostTypeCalories)]
        toAttributed:attributed
                font:nil
     foregroundColor:nil];

  [self appendString:@" ⋅ "
        toAttributed:attributed
                font:nil
     foregroundColor:self.costsLabel.textColor];
  
  // carbon
  [self appendString:costDict[@(STKTripCostTypeCarbon)]
        toAttributed:attributed
                font:nil
     foregroundColor:nil];
  
  self.costsLabel.attributedText = attributed;
}

- (void)appendString:(NSString *)string
        toAttributed:(NSMutableAttributedString *)mutable
                font:(UIFont *)font
     foregroundColor:(UIColor *)foreground
{
  if (! string)
    return;
  
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:3];
  if (font) {
    attributes[NSFontAttributeName] = font;
  }
  if (foreground) {
    attributes[NSForegroundColorAttributeName] = foreground;
  }
  NSAttributedString *add = [[NSAttributedString alloc] initWithString:string
                                                            attributes:attributes];
  [mutable appendAttributedString:add];
}

@end
