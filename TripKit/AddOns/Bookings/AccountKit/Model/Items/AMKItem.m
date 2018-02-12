//
//  AMKItem.m
//  TripKit
//
//  Created by Kuan Lun Huang on 16/02/2015.
//
//

#import "AMKItem.h"

@interface AMKItem ()

@property (nonatomic, copy) AMKDidSelectItemHandler didSelectHandler;
@property (nonatomic, assign) AMKItemActionType actionType;

@end

@implementation AMKItem

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    self.readOnly = NO;
    self.actionType = AMKItemActionType_None;
  }
  
  return self;
}

- (AMKItem *)initForExternalAccount
{
  self = [self init];
  
  if (self) {
    self.readOnly = YES;
  }
  
  return self;
}

#pragma mark - Public methods

- (void)addDidSelectHandler:(AMKDidSelectItemHandler)handler forActionType:(AMKItemActionType)type
{
  self.didSelectHandler = handler;
  self.actionType = type;
}

@end
