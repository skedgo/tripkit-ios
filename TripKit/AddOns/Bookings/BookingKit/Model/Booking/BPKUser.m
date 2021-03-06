//
//  BPKUser.m
//  TripKit
//
//  Created by Kuan Lun Huang on 9/02/2015.
//
//

#import "BPKUser.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


#import "BPKEmail.h"
#import "BPKConstants.h"

@implementation BPKUser

- (void)updateInfoFromItem:(BPKSectionItem *)item
{
  if ([item isFirstNameItem]) {
    [self updateFirstNameFromItem:item];
  } else if ([item isLastNameItem]) {
    [self updateLastNameFromItem:item];
  } else if ([item isEmailItem]) {
    [self updateEmailFromItem:item];
  }
}

- (void)updateFirstNameFromItem:(BPKSectionItem *)item
{
  if (! [item isFirstNameItem]) {
    return;
  }
  
  if ([item.value isKindOfClass:[NSString class]]) {
    self.firstName = item.value;
  }
}

- (void)updateLastNameFromItem:(BPKSectionItem *)item
{
  if (! [item isLastNameItem]) {
    return;
  }
  
  if ([item.value isKindOfClass:[NSString class]]) {
    self.lastName = item.value;
  }
}

- (void)updateEmailFromItem:(BPKSectionItem *)item
{
  if (! [item isEmailItem]) {
    return;
  }
  
  if ([item.value isKindOfClass:[NSString class]]) {
    NSString *address = item.value;
    BPKEmail *email = [[BPKEmail alloc] initWithAddress:address isPrimary:NO isVerified:NO];
    email.isReceipt = YES;
    [self setEmails:@[email]];
  }
}

#pragma mark - AMKUser

- (NSArray *)emails
{
  NSMutableArray *bpkEmails = [NSMutableArray array];
  
  NSArray *emails = [[NSUserDefaults sharedDefaults] objectForKey:kAMKEmailsUserDefaultsKey];
  
  for (NSDictionary *anEmail in emails) {
    BPKEmail *bpkEmail = [[BPKEmail alloc] initWithDictionary:anEmail];
    [bpkEmails addObject:bpkEmail];
  }
  
  return bpkEmails;
}

#pragma mark - Custom accessors

- (BPKEmail *)receiptEmail
{
  for (BPKEmail *anEmail in self.emails) {
    if (anEmail.isReceipt) {
      return anEmail;
    }
  }
  
  return nil;
}

#pragma mark - Overrides

+ (BPKUser *)sharedUser
{
  static BPKUser *_user;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _user = [[self alloc] init];
  });
  
  return _user;
}

#pragma mark - Generating form fields

- (NSDictionary *)emailFormField
{
  NSMutableDictionary *field = [NSMutableDictionary dictionary];
  if (! self.receiptEmail) {
    return nil; // means we don't have a value, so no point in sending type or IDs
  }
  
  [field setObject:[kBPKFormTypeString lowercaseString] forKey:kBPKFormType];
  [field setObject:[kBPKFormIdEmail lowercaseString] forKey:kBPKFormId];
  [field setObject:self.receiptEmail.address forKey:kBPKFormValue];
  
  return field;
}

@end
