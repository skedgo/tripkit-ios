//
//  BPKForm.m
//  TripKit
//
//  Created by Kuan Lun Huang on 3/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKForm.h"

#import "BPKConstants.h"

#import "BPKSection.h"
#import "BPKFormBuilder.h"
#import "BPKDataValidator.h"

@interface BPKForm ()

@property (nonatomic, strong) NSDictionary *rawForm;

@property (nonatomic, copy) NSArray *sections;
@property (nonatomic, copy) NSArray *items;

@property (nonatomic, copy, readonly) NSArray *invalidItems;


@end

@implementation BPKForm

+ (BOOL)canBuildFormFromRawObject:(NSDictionary *)rawForm
{
  NSString *type = rawForm[@"type"];
  return rawForm[@"form"] != nil && ([type isEqualToString:kBPKFormTypeBookingForm] || [type isEqualToString:kBPKFormTypePaymentForm]);
}

- (instancetype)initWithJSON:(NSDictionary *)json
{
  self = [self init];
  
  if (self) {
    _rawForm = json;
  }
  
  return self;
}

#pragma mark - Lazy accessors

- (NSArray *)sections
{
  if (! _sections) {
    _sections = [BPKFormBuilder buildSectionsFromForm:self];
  }
  
  return _sections;
}

- (NSArray *)items
{
  if (! _items) {
    NSMutableArray *allItems = [NSMutableArray array];
    
    for (BPKSection *section in self.sections) {
      NSArray *sectionItems = [section items];
      if (sectionItems.count > 0) {
        [allItems addObjectsFromArray:sectionItems];
      }
    }
    
    _items = [NSArray arrayWithArray:allItems];
  }
  
  return _items;
}

#pragma mark - Custom accessors

- (NSString *)title
{
  return [_rawForm objectForKey:@"title"];
}

- (NSString *)subtitle
{
  return [_rawForm objectForKey:@"subtitle"];
}

- (NSArray *)invalidItems
{
  NSMutableArray *mInvalidItems;
  
  for (NSUInteger sectionIndex = 0; sectionIndex < self.sections.count; sectionIndex++) {
    BPKSection *section = self.sections[sectionIndex];
    for (NSUInteger itemIndex = 0; itemIndex < section.items.count; itemIndex++) {
      BPKSectionItem *item = section.items[itemIndex];
      BOOL valid = [BPKDataValidator validateItem:item];
      if (! valid) {
        [mInvalidItems addObject:item];
      }
    }
  }
  
  return mInvalidItems;
}

- (BOOL)isBookingForm
{
  NSString *type = [_rawForm objectForKey:@"type"];
  return type ? [type isEqualToString:@"bookingForm"] : NO;
}

- (BOOL)isPaymentForm
{
  NSString *type = [_rawForm objectForKey:@"type"];
  return type ? [type isEqualToString:@"paymentForm"] : NO;
}

- (BOOL)isLast
{
  return [self actionIsLast];
}

- (BOOL)isValid
{
  return self.invalidItems.count == 0;
}

- (BOOL)isCancelled
{
  NSArray *sections = [BPKFormBuilder buildSectionsFromForm:self];
  for (BPKSection *section in sections) {
    BPKSectionItem *statusItem = [section bookingStatusItem];
    if (statusItem != nil) {
      id value = statusItem.value;
      if ([value isKindOfClass:[NSString class]]) {
        return [value caseInsensitiveCompare:kBPKBookingStatusCancelled] == NSOrderedSame;
      } else {
        ZAssert(false, @"booking status is not specified as string");
        return NO;
      }
    }
  }
  
  return NO;
}

- (NSDictionary *)rawForm
{
  return _rawForm;
}

#pragma mark - Getting form items

- (BPKSectionItem *)updateBookingItem
{
  for (BPKSectionItem *anItem in self.items) {
    if ([anItem isUpdateBookingItem]) {
      return anItem;
    }
  }
  
  return nil;
}

#pragma mark - From action

- (BOOL)hasAction
{
  return [self action] != nil;
}

- (BOOL)isActionEnabled
{
  if (! [self hasAction]) {
    return NO;
  }
  
  id enabledValue = [[self action] objectForKey:@"enabled"];
  return enabledValue == nil || [enabledValue boolValue];
}

- (BOOL)isActionBooking
{
  if (! [self hasAction]) {
    return NO;
  }
  
  id title = [[self action] objectForKey:@"title"];
  return [title isEqualToString:@"Book"];
}

- (NSString *)actionTitle
{
  if (! [self hasAction]) {
    return nil;
  } else {
    return [[self action] objectForKey:@"title"];
  }
}

- (NSURL *)actionURL
{
  if (! [self hasAction]) {
    return nil;
  } else {
    NSString *path = [[self action] objectForKey:@"url"];
    return path ? [NSURL URLWithString:path] : nil;
  }
}

- (NSString *)actionText
{
  if (! [self hasAction]) {
    return nil;
  } else {
    return [[self action] objectForKey:@"hudText"];
  }
}

- (BOOL)actionIsLast
{
  if (! [self hasAction]) {
    return NO;
  } else {
    NSNumber *done = [[self action] valueForKey:@"done"];
    return [done boolValue];
  }
}

#pragma mark - Public methods - Refersh

- (BOOL)isRefreshable
{
  return [self refreshURL] != nil;
}

- (NSURL *)refreshURL
{
  NSString *path = [_rawForm objectForKey:@"refreshURL"];
  return path ? [NSURL URLWithString:path] : nil;
}

- (NSURL *)refreshURLForSourceObject
{
  NSString *path = [_rawForm objectForKey:@"refreshURLForSourceObject"];
  return path ? [NSURL URLWithString:path] : nil;
}

#pragma mark - External link

- (BOOL)shoudLoadExternalLinkAutomatically
{
  if (self.sections.count != 1) {
    return NO;
  }
  
  BPKSection *theOnlySection = self.sections.firstObject;
  
  if (theOnlySection.items.count != 1) {
    return NO;
  }
  
  BPKSectionItem *item = theOnlySection.items.firstObject;
  return [item isExternalItem] && theOnlySection.footer == nil;
}

- (BPKSectionItem *)externalItem
{
  for (BPKSectionItem *item in self.items) {
    if ([item isExternalItem]) {
      return item;
    }
  }
  
  return nil;
}

#pragma mark - Private: Form action

- (NSDictionary *)action
{
  id rawAction = [_rawForm objectForKey:@"action"];
  return [rawAction isKindOfClass:[NSDictionary class]] ? rawAction : nil;
}

@end

@implementation BPKForm (Payment)

- (NSDictionary *)paymentJSON
{
  return [_rawForm objectForKey:@"payment"];
}

@end
