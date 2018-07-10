//
//  AddressBookManager.h
//  TripKit
//
//  Created by Adrian Schönig on 15/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AddressBook/AddressBook.h>

#if TARGET_OS_IPHONE

//#import "TKPermissionManager.h"
#import "TKPermissionManager+AuthorizationAlert.h"
#import "TKBaseGeocoder.h"
#import "SGAutocompletionDataProvider.h"

#define kBHKeyForRecordName     @"name"
#define kBHKeyForRecordAddress  @"address"
#define kBHKeyForRecordId       @"recordId"

typedef enum {
	TKAddressBookManagerAddressTypeUnknown = 0,
  TKAddressBookManagerAddressTypeHome,
  TKAddressBookManagerAddressTypeWork
} TKAddressBookManagerAddressType;

typedef void (^TKAddressBookManagerCompletionBlock)(NSString *string, NSArray *results);

//NS_CLASS_DEPRECATED_IOS(2_0, 9_0, "Use SGContactsManager instead")
@interface TKAddressBookManager : TKPermissionManager <SGAutocompletionDataProvider, SGGeocoder>

@property (nonatomic, strong) id<SGGeocoder> helperGeocoder;

+ (TKAddressBookManager *)sharedInstance;

- (NSArray *)fetchContactsForString:(NSString *)string
                             ofType:(TKAddressBookManagerAddressType)addressType;

/*
 * Fetches the contacts asynchronously in a background queue
 * and then calls the provided completion block with the results.
 */
- (void)fetchContactsForString:(NSString *)string
                        ofType:(TKAddressBookManagerAddressType)addressType
                    completion:(TKAddressBookManagerCompletionBlock)block;

@end

#endif
