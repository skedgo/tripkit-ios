//
//  SGPaymentSwitchCell.m
//  TripKit
//
//  Created by Kuan Lun Huang on 27/01/2015.
//
//

#import "BPKSwitchCell.h"

#import "BPKSection.h"

#import "SGLabel.h"

@interface BPKSwitchCell ()

@end

@implementation BPKSwitchCell

@synthesize didChangeValueHandler;

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [self.contentView setNeedsLayout];
  [self.contentView layoutIfNeeded];
  
  self.prompt.preferredMaxLayoutWidth = CGRectGetWidth(self.prompt.frame);
  
  [super layoutSubviews];
}

#pragma mark - Public methods

- (void)configureForPrompt:(NSString *)prompt switchValue:(BOOL)onOrOff
{
  self.prompt.text = [prompt removeTrailingNewLine];
  self.switchControl.on = onOrOff;
}

#pragma mark - BPKFormCell

- (void)configureForItem:(BPKSectionItem *)item
{
  if (! [item isSwitchItem]) {
    return;
  }
  
  [self configureForPrompt:item.title switchValue:[item.value boolValue]];
}

#pragma mark - Overrides

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark - User interactions

- (IBAction)switchChangedValue:(id)sender
{
  UISwitch *switchCtr = (UISwitch *)sender;
  
  if (self.didChangeValueHandler != nil) {
    self.didChangeValueHandler(@(switchCtr.isOn));
  }
}

@end
