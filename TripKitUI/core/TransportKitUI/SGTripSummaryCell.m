//
//  SGTripSummaryCell.m
//  TripGo
//
//  Created by Adrian Schoenig on 20/01/2014.
//
//

#import "SGTripSummaryCell.h"

@import MAKVONotificationCenter;

#ifdef TK_NO_FRAMEWORKS
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

@property (nonatomic, weak) id<STKTrip> trip;

@property (nonatomic, strong) NSTimeZone *departureTimeZone;
@property (nonatomic, strong) NSTimeZone *arrivalTimeZone;
@property (nonatomic, assign) BOOL durationFirst;
@property (nonatomic, assign) BOOL arriveBefore;

@property (nonatomic, copy) SGTripSummaryCellActionBlock actionBlock;
@property (nonatomic, copy) NSString *tripAccessibilityLabel;

@property (nonatomic, assign) UIEdgeInsets xibContentMargins;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainLabelTrailingConstraint;

@end

@implementation SGTripSummaryCell

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
  
  [self stopObservingAllTargets];
  self.trip = nil;
  
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

- (void)dealloc
{
  [self stopObservingAllTargets];
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


- (void)configureForTrip:(id<STKTrip>)trip
{
  [self configureForTrip:trip
               highlight:STKTripCostTypeCount
                   faded:NO
             actionTitle:nil
             actionBlock:nil];
}

- (void)configureForTrip:(id<STKTrip>)trip
               highlight:(STKTripCostType)costType
             actionTitle:(NSString *)actionTitle
             actionBlock:(SGTripSummaryCellActionBlock)actionBlock
{
  [self configureForTrip:trip
                 forNano:NO
                   faded:NO
               highlight:costType
             actionTitle:actionTitle
             actionBlock:actionBlock];
}


- (void)configureForTrip:(id<STKTrip>)trip
               highlight:(STKTripCostType)costType
                   faded:(BOOL)faded
             actionTitle:(NSString *)actionTitle
             actionBlock:(SGTripSummaryCellActionBlock)actionBlock
{
  [self configureForTrip:trip
                 forNano:NO
                   faded:faded
               highlight:costType
             actionTitle:actionTitle
             actionBlock:actionBlock];
}

- (void)configureForNanoTrip:(id<STKTrip>)trip
                   highlight:(STKTripCostType)costType
{
  [self configureForTrip:trip
                 forNano:YES
                   faded:YES
               highlight:costType
             actionTitle:nil
             actionBlock:nil];
}

- (void)updateForTrip:(id<STKTrip>)trip
            highlight:(STKTripCostType)costType
{
  [self updateForTrip:trip forNano:NO highlight:costType];
}

- (void)adjustToFillContentView
{
  self.contentView.layoutMargins = UIEdgeInsetsZero;
}

- (void)adjustToFillContentViewWidth
{
  self.contentView.layoutMargins = UIEdgeInsetsMake(self.xibContentMargins.top, 0, self.xibContentMargins.bottom, 0);
}

#pragma mark - Private: configuration

- (void)configureForTrip:(id<STKTrip>)trip
                 forNano:(BOOL)nano
                   faded:(BOOL)faded
               highlight:(STKTripCostType)costType
             actionTitle:(NSString *)actionTitle
             actionBlock:(SGTripSummaryCellActionBlock)actionBlock
{
  if (actionTitle) {
    self.actionBlock = actionBlock;
    [self.actionButton setTitle:actionTitle forState:UIControlStateNormal];
    self.actionButton.hidden = NO;
  } else {
    self.actionButton.hidden = YES;
  }
  
  if ([trip respondsToSelector:@selector(accessibilityLabel)]) {
    self.tripAccessibilityLabel = [(id)trip accessibilityLabel];
  }
  
  // updating colours, adds all the text
  [self updateForTrip:trip forNano:nano highlight:costType];
  
  // segments
  self.segmentView.allowWheelchairIcon = self.allowWheelchairIcon;
  [self.segmentView configureForSegments:[trip segmentsWithVisibility:STKTripSegmentVisibilityInSummary]
                          allowSubtitles:!nano
                          allowInfoIcons:!nano];

  CGFloat alpha = faded ? 0.2f : 1.0f;
  self.mainLabel.alpha    = alpha;
  self.segmentView.alpha  = alpha;
  self.costsLabel.alpha   = alpha;
  self.actionButton.alpha = alpha;
  
  if (nano) {
    return;
  }
  
  // ticks
  self.showTickIcon  = NO;
  
  // subscript to time notifications
  self.trip = trip;
  [self updateAlertStatus];
  
  [self stopObservingAllTargets];
  if ([trip isKindOfClass:[NSObject class]]) {
    __weak typeof(self) weakSelf = self;
    [(NSObject *)trip addObservationKeyPath:@[@"departureTime", @"arrivalTime"]
                                    options:NSKeyValueObservingOptionNew
                                      block:
     ^(MAKVONotification *notification) {
       typeof(self) strongSelf = weakSelf;
       if (strongSelf && [strongSelf trip] == [notification target]) {
         dispatch_async(dispatch_get_main_queue(), ^{
           [strongSelf updateTimeStrings];
           
           // Inefficient, but let's just redraw the images as their real-time and warning status might have changed
           NSArray *segments = [[strongSelf trip] segmentsWithVisibility:STKTripSegmentVisibilityInSummary];
           strongSelf.segmentView.allowWheelchairIcon = strongSelf.allowWheelchairIcon;
           [strongSelf.segmentView configureForSegments:segments
                                         allowSubtitles:!nano
                                         allowInfoIcons:!nano];
         });
       }
     }];
    
    [(NSObject *)trip addObservationKeyPath:@[@"hasReminder"]
                                    options:NSKeyValueObservingOptionNew
                                      block:
     ^(MAKVONotification *notification) {
       typeof(self) strongSelf = weakSelf;
       if (strongSelf && [strongSelf trip] == [notification target]) {
         dispatch_async(dispatch_get_main_queue(), ^{
           [strongSelf updateAlertStatus];
         });
       }
     }];
  }
}

- (void)updateForTrip:(id<STKTrip>)trip
              forNano:(BOOL)nano
            highlight:(STKTripCostType)costType
{
  if (nano) {
    if (costType == STKTripCostTypeTime) {
      NSString *start = [SGStyleManager timeString:[trip departureTime] forTimeZone:self.departureTimeZone];
      NSString *end = [SGStyleManager timeString:[trip arrivalTime] forTimeZone:self.arrivalTimeZone];
      self.mainLabel.text = [NSString stringWithFormat:@"%@ to %@", start, end];
      
    } else {
      NSDictionary *costValues = [trip costValues];
      self.mainLabel.text = costValues[@(costType)];
    }
    return;
  }
  
  // time and duration
  [self addTimeStringForDeparture:trip.departureTime
                          arrival:trip.arrivalTime
                departureTimeZone:trip.departureTimeZone
                  arrivalTimeZone:[trip respondsToSelector:@selector(arrivalTimeZone)] ? [trip arrivalTimeZone] : [trip departureTimeZone]
                  focusOnDuration:! [trip departureTimeIsFixed]
              queryIsArriveBefore:[trip isArriveBefore]];
  
  // costs
  if (self.showCosts) {
    [self addCosts:[trip costValues]];
  }
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
  if (self.actionBlock) {
    self.actionBlock(sender);
  }
}

#pragma mark - UIAccessibility

- (NSString *)accessibilityLabel
{
  if (self.showAlertIcon) {
    return [NSString stringWithFormat:@"%@ - %@", self.tripAccessibilityLabel, NSLocalizedStringFromTableInBundle(@"Has reminder", @"Shared", [SGStyleManager bundle], @"Accessibility annotation for trips which have a reminder set.")];
  } else {
    return self.tripAccessibilityLabel;
  }
}

#pragma mark - Private: notifications

- (void)updateAlertStatus
{
  self.showAlertIcon = [self.trip respondsToSelector:@selector(hasReminder)] && [self.trip hasReminder];
}

- (void)updateTimeStrings
{
  [self updateTimeStringForDeparture:[self.trip departureTime]
                             arrival:[self.trip arrivalTime]];
}

#pragma mark - Private: Others

- (void)didInitialize
{
  [SGStyleManager addDefaultOutline:self.wrapper];

  self.showCosts = YES;
  
  [self.actionButton addTarget:self
                        action:@selector(actionButtonPressed:)
              forControlEvents:UIControlEventTouchUpInside];
  
  _xibContentMargins = self.contentView.layoutMargins;
  
  _preferredTintColor = self.tintColor;
}

- (void)addTimeStringForDeparture:(NSDate *)departure
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
  
  [self updateTimeStringForDeparture:departure arrival:arrival];
}

- (void)updateTimeStringForDeparture:(NSDate *)departure
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

- (void)addCosts:(NSDictionary *)costDict
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
