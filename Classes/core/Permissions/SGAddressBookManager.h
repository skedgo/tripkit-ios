//
//  AddressBookManager.h
//  TripGo
//
//  Created by Adrian Schönig on 15/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AddressBook/AddressBook.h>

//#import "SGPermissionManager.h"
#import "SGPermissionManager+AuthorizationAlert.h"
#import "SGBaseGeocoder.h"
#import "SGAutocompletionDataProvider.h"

#define kBHKeyForRecordName     @"name"
#define kBHKeyForRecordAddress  @"address"
#define kBHKeyForRecordId       @"recordId"

typedef enum {
	SGAddressBookManagerAddressTypeUnknown = 0,
  SGAddressBookManagerAddressTypeHome,
  SGAddressBookManagerAddressTypeWork
} SGAddressBookManagerAddressType;

typedef void (^SGAddressBookManagerCompletionBlock)(NSString *string, NSArray *results);

@interface SGAddressBookManager : SGPermissionManager <SGAutocompletionDataProvider, SGGeocoder>

@property (nonatomic, strong) id<SGGeocoder> helperGeocoder;

+ (SGAddressBookManager *)sharedInstance;

- (NSArray *)fetchContactsForString:(NSString *)string
                             ofType:(SGAddressBookManagerAddressType)addressType;

/*
 * Fetches the contacts asynchronously in a background queue
 * and then calls the provided completion block with the results.
 */
- (void)fetchContactsForString:(NSString *)string
                        ofType:(SGAddressBookManagerAddressType)addressType
                    completion:(SGAddressBookManagerCompletionBlock)block;

@end
