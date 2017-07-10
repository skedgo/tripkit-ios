//
//  SGBPStepperCell.m
//  TripGo
//
//  Created by Kuan Lun Huang on 2/02/2015.
//
//

#import "BPKStepperCell.h"

#import "BPKSection.h"

@interface BPKStepperCell ()

@end

@implementation BPKStepperCell

@synthesize didChangeValueHandler;

- (void)configureForMainTitle:(NSString *)mainTitle
                     subtitle:(NSString *)subtitle 
                        value:(double)value
{
  self.mainLabel.text = mainTitle;
  self.subtitleLabel.text = subtitle;
  self.valueLabel.text = [[NSNumber numberWithDouble:value] stringValue];
  self.stepper.value = value;
}

#pragma mark - BPKFormCell

- (void)configureForItem:(BPKSectionItem *)item
{
  [self configureForMainTitle:[self mainTitleForItem:item]
                     subtitle:[self subtitleForItem:item]
                        value:[self valueForItem:item]];
  
  if (item.minValue != nil) {
    self.stepper.minimumValue = [item.minValue doubleValue];
  }
  
  if (item.maxValue != nil) {
    self.stepper.maximumValue = [item.maxValue doubleValue];
  }
}

#pragma mark - Private methods

- (NSString *)mainTitleForItem:(BPKSectionItem *)item
{
  return [item.json objectForKey:kBPKFormTitle];
}

- (NSString *)subtitleForItem:(BPKSectionItem *)item
{
  return [item.json objectForKey:kBPKFormSubTitle];
}

- (double)valueForItem:(BPKSectionItem *)item
{
  return [[item.json objectForKey:kBPKFormValue] doubleValue];
}

#pragma mark - User interactions

- (IBAction)steppDidChangeValue:(UIStepper *)sender
{
  self.valueLabel.text = [[NSNumber numberWithDouble:sender.value] stringValue];
  
  if (self.didChangeValueHandler != nil) {
    self.didChangeValueHandler(@(sender.value));
  }
}

@end
