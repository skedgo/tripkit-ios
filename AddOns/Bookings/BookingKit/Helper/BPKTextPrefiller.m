//
//  BPKTextPrefiller.m
//  TripGo
//
//  Created by Kuan Lun Huang on 31/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKTextPrefiller.h"

// Checking item type
#import "BPKSection.h"

// Prefill source
#import "BPKUser.h"

@implementation BPKTextPrefiller

+ (NSString *)prefillTextForItem:(BPKSectionItem *)item
{
  if ([item isCCFirstNameItem]) {
    return [self prefillCardHolderFirstName];
  } else if ([item isCCLastNameItem]) {
    return [self prefillCardHolderLastName];
  } else {
    return nil;
  }
}

#pragma mark - Private

+ (NSString *)prefillCardHolderFirstName
{
  BPKUser *user = [BPKUser sharedUser];
  return user.firstName;
}

+ (NSString *)prefillCardHolderLastName
{
  BPKUser *user = [BPKUser sharedUser];
  return user.lastName;
}

+ (NSString *)prefillCardNumber
{
  return nil;
}

+ (NSString *)prefillCardCVN
{
  return nil;
}

+ (NSString *)prefillCardExpiryMonth
{
  return nil;
}

+ (NSString *)prefillCardExpiryYear
{
  return nil;
}

@end
