//
//  BPKManager.m
//  TripKit
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import "BPKManager.h"

@implementation BPKManager

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _wantsReminder = NO;
    _reminderHeadway = 3;
  }
  
  return self;
}

@end
