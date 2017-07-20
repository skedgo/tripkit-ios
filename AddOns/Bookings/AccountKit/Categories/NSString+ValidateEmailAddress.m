//
//  NSString+ValidateEmailAddress.m
//  TravelGo
//
//  Created by Brian Huang on 11/12/2014.
//  Copyright (c) 2014 SkedGo. All rights reserved.
//

#import "NSString+ValidateEmailAddress.h"

@implementation NSString (ValidateEmailAddress)

- (BOOL)isValidEmail
{
  BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
  NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
  NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
  NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  return [emailTest evaluateWithObject:self];
}

@end
