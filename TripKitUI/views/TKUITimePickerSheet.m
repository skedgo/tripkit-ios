//
//  TKUITimePickerSheet.m
//  TripGo
//
//  Created by Adrian Schoenig on 24/09/13.
//
//

#import "TKUITimePickerSheet.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#endif

#import "TripKit/TripKit-Swift.h"

@interface TKUITimePickerSheet ()

@property (nonatomic, assign) BOOL didSetTime;

@property (nonatomic, weak) UISegmentedControl *timeTypeSelector;
@property (nonatomic, weak) UISegmentedControl *doneSelector;

@property (nonatomic, assign) BOOL includeTimeType;

@end

@implementation TKUITimePickerSheet

#pragma mark - UIView

- (instancetype)initWithTime:(nullable NSDate *)time
                    timeType:(SGTimeType)timeType
                    timeZone:(NSTimeZone *)timeZone
{
  self = [super initWithFrame:CGRectMake(0, 0, 320, 216)];
  if (self) {
    self.includeTimeType = YES;
    
    [self commonInit];

    if (! time) {
      time = [NSDate date];
    }
    self.timePicker.datePickerMode = UIDatePickerModeDateAndTime;
    self.timePicker.timeZone = timeZone;
    self.timePicker.date     = time;
    [self setSelectedTimeType:timeType];
  }
  return self;
}

- (instancetype)initWithTime:(nullable NSDate *)time
                    timeZone:(NSTimeZone *)timeZone
{
  self = [super initWithFrame:CGRectMake(0, 0, 320, 216)];
  if (self) {
    self.includeTimeType = NO;
    
    [self commonInit];

    if (! time) {
      time = [NSDate date];
    }
    self.timePicker.datePickerMode = UIDatePickerModeDateAndTime;
    self.timePicker.timeZone = timeZone;
    self.timePicker.date     = time;
  }
  return self;
}

- (instancetype)initWithDate:(nullable NSDate *)time
                    timeZone:(NSTimeZone *)timeZone
{
  self = [super initWithFrame:CGRectMake(0, 0, 320, 216)];
  if (self) {
    self.includeTimeType = NO;
    
    [self commonInit];
    
    if (! time) {
      time = [NSDate date];
    }
    self.timePicker.datePickerMode = UIDatePickerModeDate;
    self.timePicker.timeZone = timeZone;
    self.timePicker.date     = time;
    self.timePicker.minimumDate = nil;
    self.timePicker.maximumDate = nil;
  }
  return self;
}

- (void)setTimePicker:(UIDatePicker *)timePicker {
  if (timePicker != nil) {
    _timePicker = timePicker;
  }
}

- (NSDate *)selectedDate
{
  return self.timePicker.date;
}

- (SGTimeType)selectedTimeType
{
  if (! self.includeTimeType)
    return SGTimeTypeNone;
  
  if (self.timeTypeSelector.selectedSegmentIndex == 0)
    return SGTimeTypeLeaveASAP;
  
  if (self.timeTypeSelector.selectedSegmentIndex == 1)
    return SGTimeTypeLeaveAfter;
  
  if (self.timeTypeSelector.selectedSegmentIndex == 2)
    return SGTimeTypeArriveBefore;
  
  ZAssert(false, @"Unexpected state!");
  return SGTimeTypeNone;
}

#pragma mark - User Interaction

- (IBAction)doneButtonPressed:(id)sender
{
  self.doneSelector.selectedSegmentIndex = -1;
  
	if ([self isBeingOverlaid]) {
		[self tappedOverlay:sender];
	} else if ([self.delegate respondsToSelector:@selector(timePickerRequestsResign:)]) {
		[self.delegate timePickerRequestsResign:self];
  }
}


- (IBAction)nowButtonPressed:(id)sender
{
  if (self.selectAction) {
    self.selectAction(SGTimeTypeLeaveASAP, [NSDate date]);
    self.selectAction = nil;
  }

	if ([self isBeingOverlaid]) {
		[self tappedOverlay:sender];
	} else if ([self.delegate respondsToSelector:@selector(timePickerRequestsResign:)]) {
		[self.delegate timePickerRequestsResign:self];
	} else {
    [self.timePicker setDate:[NSDate date] animated:YES];
  }
}

- (IBAction)timePickerChanged:(id)sender
{
#pragma unused(sender)
  self.didSetTime = YES;
  if (SGTimeTypeLeaveASAP == [self selectedTimeType]) {
    [self setSelectedTimeType:SGTimeTypeLeaveAfter];
  } else {
    [self setSelectedTimeType:[self selectedTimeType]];
  }
}

- (IBAction)timeSelectorChanged:(id)sender
{
  if (SGTimeTypeLeaveASAP == [self selectedTimeType]) {
    [self nowButtonPressed:sender];
  } else {
    [self setSelectedTimeType:[self selectedTimeType]];
  }
}

- (void)tappedOverlay:(id)sender
{
  if (self.selectAction && self.didSetTime) {
    self.selectAction([self selectedTimeType], self.timePicker.date);
    self.selectAction = nil;
  }
  
  [super tappedOverlay:sender];
}


#pragma mark - Private methods

- (void)commonInit
{
  static const CGFloat kButtonHeight = 44;
  
  self.backgroundColor = [UIColor whiteColor];
  
  UIDatePicker *timePicker = [[UIDatePicker alloc] init];
  timePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * -31]; // 1 month ago
  timePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 31]; // 1 month
  timePicker.locale = [SGStyleManager applicationLocale]; // Set the 24h setting
  timePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [timePicker addTarget:self
                 action:@selector(timePickerChanged:)
       forControlEvents:UIControlEventValueChanged];
  [self addSubview:timePicker];
  self.timePicker = timePicker;
  
  CGRect timePickerFrame = timePicker.frame;
  timePickerFrame.size.width = CGRectGetWidth(self.frame);
  timePickerFrame.origin.y = kButtonHeight;
  self.timePicker.frame = timePickerFrame;

  UISegmentedControl *timeTypeSelector;
  if (self.includeTimeType) {
     timeTypeSelector = [[UISegmentedControl alloc] initWithItems:@[
                                                                    Loc.Now,
                                                                    Loc.LeaveAt,
                                                                    Loc.ArriveBy]];
    [timeTypeSelector addTarget:self
                         action:@selector(timeSelectorChanged:)
               forControlEvents:UIControlEventValueChanged];
    self.timeTypeSelector = timeTypeSelector;
  }
  
  UISegmentedControl *doneSelector = [[UISegmentedControl alloc] initWithItems:@[Loc.Done]];
  [doneSelector addTarget:self
                  action:@selector(doneButtonPressed:)
        forControlEvents:UIControlEventValueChanged];
  self.doneSelector = doneSelector;

  UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(timePickerFrame), kButtonHeight)];
  toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  NSMutableArray *items = [NSMutableArray array];
  if (timeTypeSelector) {
    [items addObject:[[UIBarButtonItem alloc] initWithCustomView:timeTypeSelector]];
  }
  [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
  [items addObject:[[UIBarButtonItem alloc] initWithCustomView:doneSelector]];
  toolbar.items = items;
  
  [toolbar setBackgroundImage:[UIImage new]
           forToolbarPosition:UIToolbarPositionAny
                   barMetrics:UIBarMetricsDefault];
  toolbar.backgroundColor = self.backgroundColor;
  [self addSubview:toolbar];

  self.frame = CGRectMake(0, 0, CGRectGetWidth(timePickerFrame), CGRectGetHeight(timePickerFrame) + kButtonHeight);
}

- (void)setSelectedTimeType:(SGTimeType)timeType
{
  switch (timeType) {
    case SGTimeTypeLeaveASAP:
      self.timeTypeSelector.selectedSegmentIndex = 0;
      [self.timePicker setDate:[NSDate date] animated:YES];
      break;
      
    case SGTimeTypeLeaveAfter: {
      self.timeTypeSelector.selectedSegmentIndex = 1;
      break;
    }
      
    case SGTimeTypeArriveBefore: {
      self.timeTypeSelector.selectedSegmentIndex = 2;
      break;
    }
      
    default:
      break;
  }
  
  self.didSetTime = YES;
  if ([self.delegate respondsToSelector:@selector(timePicker:pickedDate:forType:)]) {
    [self.delegate timePicker:self
                   pickedDate:self.timePicker.date
                      forType:timeType];
  }
}

@end
