//
//  BPKUser.h
//  TripKit
//
//  Created by Kuan Lun Huang on 9/02/2015.
//
//

#import "AMKUser.h"

#import "BPKSection.h"

@class BPKEmail;

@interface BPKUser : AMKUser

@property (nonatomic, strong, readonly) BPKEmail *receiptEmail;

+ (BPKUser *)sharedUser;

- (void)updateInfoFromItem:(BPKSectionItem *)item;
- (void)updateFirstNameFromItem:(BPKSectionItem *)item;
- (void)updateLastNameFromItem:(BPKSectionItem *)item;
- (void)updateEmailFromItem:(BPKSectionItem *)item;

- (NSDictionary *)emailFormField; // can be nil

@end
