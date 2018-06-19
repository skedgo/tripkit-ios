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
  
  NSNumber *epochTime = [item value];
  if (epochTime != nil) {
    date = [NSDate dateWithTimeIntervalSince1970:epochTime.integerValue];
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
