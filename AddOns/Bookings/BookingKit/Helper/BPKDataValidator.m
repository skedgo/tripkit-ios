//
//  BPKDataValidator.m
//  TripGo
//
//  Created by Kuan Lun Huang on 31/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKDataValidator.h"

#import "BPKBookingKit.h"

@implementation BPKDataValidator

+ (BOOL)validateItem:(BPKSectionItem *)item
{
  if ([item isStringItem]) {
    return [self validateStringItem:item];
  } else if ([item isSwitchItem]) {
    return [self validateSwichItem:item];
  } else {
    return YES;
  }
}

#pragma mark - Private

+ (id)valueForItem:(BPKSectionItem *)item
{
  return [item.json objectForKey:kBPKFormValue];
}

+ (BOOL)validateStringItem:(BPKSectionItem *)item
{
  id value = [self valueForItem:item];
  if (! [value isKindOfClass:[NSString class]]) {
    return NO;
  }
  
  NSString *string = (NSString *)value;
  if (string.length == 0 && item.isRequired) {
    return NO;
  } else {
    return YES;
  }
}

+ (BOOL)validateSwichItem:(BPKSectionItem *)item
{
  id value = [self valueForItem:item];
  if (! [value isKindOfClass:[NSNumber class]]) {
    return NO;
  }
  
  BOOL onOrOff = ((NSNumber *)value).boolValue;
  if (onOrOff == NO && item.isRequired) {
    return NO;
  } else {
    return YES;
  }
}

@end
