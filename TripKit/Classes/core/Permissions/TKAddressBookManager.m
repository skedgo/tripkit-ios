//
//  AddressBookManager.m
//  TripKit
//
//  Created by Adrian Schönig on 15/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKAddressBookManager.h"

#import "TKTripKit.h"
#import "TripKit/TripKit-Swift.h"

#if TARGET_OS_IPHONE

#import "TKAutocompletionResult.h"

#define kBHAddressBookValueForAddress 5

@implementation TKAddressBookManager

#pragma mark - Public methods

+ (TKAddressBookManager *)sharedInstance
{
  static dispatch_once_t pred = 0;
  __strong static id _sharedObject = nil;
  dispatch_once(&pred, ^{
    _sharedObject = [[self alloc] init];
  });
  return _sharedObject;
}

- (void)fetchContactsForString:(NSString *)string
                        ofType:(TKAddressBookManagerAddressType)addressType
                    completion:(TKAddressBookManagerCompletionBlock)block
{
  if (! [self isAuthorized]) {
    block(string, @[]);
    return;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    NSArray *result = [self fetchContactsForString:string ofType:addressType];
    dispatch_sync(dispatch_get_main_queue(), ^{
      block(string, result);
    });
  });
}

- (NSArray *)fetchContactsForString:(NSString *)string
                             ofType:(TKAddressBookManagerAddressType)addressType
{
  if (! [self isAuthorized]) {
    return @[];
  }
  
  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
  if (addressBook != NULL) {
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef requestError) {
#pragma unused (granted, requestError) // we have no way to rever from this
    });
  }
  
  if (NULL != addressBook) {
    NSArray * matchingPeople = (__bridge_transfer NSArray *)ABAddressBookCopyPeopleWithName(addressBook, (__bridge_retained CFStringRef)string);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[matchingPeople count]];
    
    for (id object in matchingPeople) {
      ABRecordRef person = (__bridge ABRecordRef)object;
      [result addObjectsFromArray:[[self class] addressesForRecord:person ofType:addressType]];
    }
    CFRelease(addressBook);
    return result;
  } else {
    return @[];
  }
}

#pragma mark - Helpers

+ (NSArray *)addressesForRecord:(ABRecordRef)record
                         ofType:(TKAddressBookManagerAddressType)addressType
{
  NSNumber *recordId = @(ABRecordGetRecordID(record));
  
  ABMultiValueRef addresses = ABRecordCopyValue(record, kBHAddressBookValueForAddress);
  NSArray *addressArray = (__bridge_transfer NSArray*) ABMultiValueCopyArrayOfAllValues(addresses);
  
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:[addressArray count]];
  
  for (NSUInteger i = 0; i < addressArray.count; i++) {
		
    NSString *labelString = (__bridge_transfer NSString *) ABMultiValueCopyLabelAtIndex(addresses, i);
    BOOL matches = NO;
    switch (addressType) {
      case TKAddressBookManagerAddressTypeUnknown:
        matches = YES;
        break;
      
      case TKAddressBookManagerAddressTypeHome:
        matches = [labelString isEqualToString:(__bridge NSString *)kABHomeLabel];
        break;
        
      case TKAddressBookManagerAddressTypeWork:
        matches = [labelString isEqualToString:(__bridge NSString *)kABWorkLabel];
        break;
    }
    if (!matches) {
      continue;
    }
    
    NSString *name = [self getAddressName:record withLabel:labelString];
    NSString *addressString = [TKLocationHelper postalAddressForAddressDictionary:[addressArray objectAtIndex:i]];
		
    if (addressString && name && recordId) {
      [result addObject:@{kBHKeyForRecordName: name,
													kBHKeyForRecordAddress: addressString,
													kBHKeyForRecordId: recordId }
       ];
    }
  }
  
  CFRelease(addresses);
  
  return result;
}

#pragma mark - TKPermissionManager implementations

- (BOOL)featureIsAvailable
{
  return YES;
}

- (BOOL)authorizationRestrictionsApply
{
  return YES;
}

- (TKAuthorizationStatus)authorizationStatus
{
  if ([self authorizationRestrictionsApply]) {
    int status = ABAddressBookGetAuthorizationStatus();
    switch (status) {
      case kABAuthorizationStatusAuthorized:
        return TKAuthorizationStatusAuthorized;
      case kABAuthorizationStatusDenied:
        return TKAuthorizationStatusDenied;
      case kABAuthorizationStatusRestricted:
        return TKAuthorizationStatusRestricted;
      case kABAuthorizationStatusNotDetermined:
        return TKAuthorizationStatusNotDetermined;
    }
  }
  
  // authorized by default otherwise
  return TKAuthorizationStatusAuthorized;
}

- (void)askForPermission:(void (^)(BOOL enabled))completion
{
  if (! [self authorizationRestrictionsApply])
    return;

  dispatch_queue_t originalQueue = dispatch_get_main_queue();

  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
  if (addressBook != NULL) {
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef requestError) {
      dispatch_sync(originalQueue, ^{
        completion(granted && (requestError == nil));
      });
    });
  }
}

- (NSString *)authorizationAlertText
{
  return NSLocalizedStringFromTableInBundle(@"You previously denied this app access to your contacts. Please go to the Settings app > Privacy > Contacts and authorise this app to use this feature.", @"Shared", [TKStyleManager bundle], @"Contacts authorisation needed text");
}

#pragma mark - Private methods

+ (NSString *)getAddressName:(ABRecordRef)record
                   withLabel:(NSString *)label
{
  NSString *compositeName = (__bridge_transfer NSString *)ABRecordCopyCompositeName(record);
  NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
  
  // For non-persons (where display doesn't include first name or first name is null), just return the name
  if (firstName == nil || [compositeName rangeOfString:firstName].location == NSNotFound)
    return compositeName;
  
  // For person's name them "Adrian's Home", etc.
  if ([label isEqualToString:(__bridge NSString *)kABHomeLabel]) {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@'s Home", @"Shared", [TKStyleManager bundle], nil), firstName];
  } else if ([label isEqualToString:(__bridge NSString *)kABWorkLabel]) {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@'s Work", @"Shared", [TKStyleManager bundle], nil), firstName];
  } else {
    return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@'s", @"Shared", [TKStyleManager bundle], @"Name for a {%@}'s place if it's unclear if it's home, work or something else."), firstName];
  }
}

@end

#endif
