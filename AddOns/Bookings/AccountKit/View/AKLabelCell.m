//
//  SGUserAccountStandardCell.m
//  WotGo
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AKLabelCell.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#import "TripKitAddOns/TripKitAddOns-Swift.h"
#endif



@interface AKLabelCell ()

@end

@implementation AKLabelCell

@synthesize item = _item;

+ (AKLabelCell *)sharedInstance
{
  static AKLabelCell *_cell;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    _cell = [[self alloc] init];
  });
  
  return _cell;
}

#pragma mark - AKItemCell protocol

- (void)configureForItem:(AMKItem *)item
{
  ZAssert(item != nil, @"Item is missing");
  
  [self configureWithTitle:item.primaryText subtitle:item.secondaryText];
  
  if ([self shouldCenterTitle]) {
    [self adjustLayoutForCenteredTitle];
  }
  
  if (item.readOnly) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  } else {
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
  }
  
  _item = item;
}

#pragma mark - Public methods

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle
{
  _primaryLabel.text = title;
  _secondaryLabel.text = subtitle;
}

@end
