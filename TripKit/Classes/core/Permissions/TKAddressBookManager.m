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

- (SGAuthorizationStatus)authorizationStatus
{
  if ([self authorizationRestrictionsApply]) {
    int status = ABAddressBookGetAuthorizationStatus();
    switch (status) {
      case kABAuthorizationStatusAuthorized:
        return SGAuthorizationStatusAuthorized;
      case kABAuthorizationStatusDenied:
        return SGAuthorizationStatusDenied;
      case kABAuthorizationStatusRestricted:
        return SGAuthorizationStatusRestricted;
      case kABAuthorizationStatusNotDetermined:
        return SGAuthorizationStatusNotDetermined;
    }
  }
  
  // authorized by default otherwise
  return SGAuthorizationStatusAuthorized;
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

#pragma mark - SGGeocoder

- (void)geocodeString:(NSString *)inputString
           nearRegion:(MKMapRect)mapRect
              success:(SGGeocoderSuccessBlock)success
              failure:(nullable SGGeocoderFailureBlock)failure
{
#pragma unused(failure)
  NSArray<TKAutocompletionResult *> *results = [self autocompleteFast:inputString
                                                           forMapRect:mapRect];
  [TKBaseGeocoder namedCoordinatesForAutocompletionResults:results
                                             usingGeocoder:self.helperGeocoder
                                                nearRegion:mapRect
                                                completion:
   ^(NSArray<TKNamedCoordinate *> * _Nonnull coordinates) {
     success(inputString, coordinates);
   }];
}


#pragma mark - SGAutocompletionDataProvider

- (NSArray *)autocompleteFast:(NSString *)string forMapRect:(MKMapRect)mapRect
{
#pragma unused (mapRect) // search for contacts everywhere, address book matchs, don't have coordinate information,s o we can't score based on map rect here
  if (string.length == 0) {
    return @[];
  }
  
  NSArray *matches = [self fetchContactsForString:string
                                           ofType:TKAddressBookManagerAddressTypeUnknown];
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:matches.count];
  for (NSDictionary *addressDict in matches) {
    TKAutocompletionResult *result = [[TKAutocompletionResult alloc] init];
    result.provider = self;
    result.object   = addressDict;
    result.title    = addressDict[kBHKeyForRecordName];
    result.subtitle = addressDict[kBHKeyForRecordAddress];
    result.image    = [TKAutocompletionResult imageForType:TKAutocompletionSearchIconContact];

    NSUInteger nameScore = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:string
                                                                                candidate:result.title];

    NSUInteger addressScore = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:string
                                                                                   candidate:result.subtitle];
    NSUInteger rawScore = MIN(100, (NSInteger) (nameScore + addressScore / 2));

    result.score = [TKAutocompletionResult rangedScoreForScore:rawScore
                                                betweenMinimum:50 andMaximum:90];
    
    [array addObject:result];
  }
  
  return array;
}

- (id<MKAnnotation>)annotationForAutocompletionResult:(TKAutocompletionResult *)result
{
  if ([result.object isKindOfClass:[NSDictionary class]]) {
    NSDictionary *contactDictionary = result.object;
    return [[TKNamedCoordinate alloc] initWithName:contactDictionary[kBHKeyForRecordName]
                                           address:contactDictionary[kBHKeyForRecordAddress]];
  } else {
    ZAssert(false, @"Unexpected object: %@", result.object);
    return nil;
  }
}

#if TARGET_OS_IPHONE
- (NSString *)additionalActionString
{
  if ([self isAuthorized]) {
    return nil;
  } else {
    return NSLocalizedStringFromTableInBundle(@"Include contacts", @"Shared", [TKStyleManager bundle], @"Include contacts.");
  }
}

- (void)additionalActionForPresenter:(UIViewController *)presenter completion:(SGAutocompletionDataActionBlock)actionBlock
{
  [self tryAuthorizationForSender:nil
                 inViewController:presenter
                       completion:^(BOOL enabled) {
    actionBlock(enabled);
  }];
}
#endif


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
