//
//  AKFbkProfile.m
//  TripKit
//
//  Created by Kuan Lun Huang on 15/09/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "AKFbkProfile.h"

@interface AKFbkProfile ()

@property (nonatomic, strong) ACAccount *account;

@end

@implementation AKFbkProfile

#pragma mark - Public methods

- (AKFbkProfile *)initWithAccount:(ACAccount *)account
{
  self = [self init];
  
  if (self) {
    _account = account;
  }
  
  return self;
}

- (NSString *)username
{
  if (self.account != nil) {
    return [[self.account valueForKey:@"properties"] valueForKey:@"ACUIDisplayUsername"];
  }
  
  return nil;
}

- (NSString *)fullname
{
  if (self.account != nil) {
    return [[self.account valueForKey:@"properties"] valueForKey:@"ACPropertyFullName"];
  }
  
  return nil;
}

@end
