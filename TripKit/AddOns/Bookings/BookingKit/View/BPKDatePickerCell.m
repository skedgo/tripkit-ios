//
//  SGPayPickerCell.m
//  TripKit
//
//  Created by Kuan Lun Huang on 29/01/2015.
//
//

#import "BPKDatePickerCell.h"

#import "BPKSection.h"

#import "BPKConstants.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#import "TripKitUI/TripKitUI-Swift.h"
#endif


@interface BPKDatePickerCell ()

@property (weak, nonatomic) IBOutlet UIDatePicker *picker;

@end

@implementation BPKDatePickerCell

@synthesize didChangeValueHandler;

- (void)configureForDate:(NSDate *)date
{
  _picker.date = date ?: [NSDate date];
  
  // Don't go back to the past.
  _picker.minimumDate = [NSDate date];
}

#pragma mark - BPKFormCell

- (void)configureForItem:(BPKSectionItem *)item
{
  NSDate *date;
  
  if (! [item isDateItem]) {
    return;
  }
  
  id rawDate = [item value];
  if (rawDate != nil) {
    date = [TKParserHelper parseDate:rawDate];
  }
  
  [self configureForDate:date];
}

#pragma mark - User interactions

- (IBAction)pickerChangedValue:(UIDatePicker *)sender
{
  NSDate *newDate = sender.date;
  
  if (self.didChangeValueHandler != nil) {
    self.didChangeValueHandler(newDate);
  }
}


@end
