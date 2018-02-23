//
//  AMKUser.h
//  TripKit
//
//  Created by Kuan Lun Huang on 9/02/2015.
//
//

#import <Foundation/Foundation.h>

#import "AMKEmail.h"

static NSString *const kAMKFirstNameUserDefaultsKey   = @"AMK.Defaults.firstName";
static NSString *const kAMKLastNameUserDefaultsKey    = @"AMK.Defaults.lastName";
static NSString *const kAMKEmailsUserDefaultsKey      = @"AMK.Defaults.emails";
static NSString *const kAMKNameUserDefaultsKey        = @"AMK.Defaults.name";
static NSString *const kAMKAppDataUserDefaultsKey     = @"AMK.Defaults.appData";

@interface AMKUser : NSObject

// Basic info
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSDictionary *appData;

+ (AMKUser *)sharedUser;

- (NSString *)compositeName;
- (BOOL)hasSignedUp;

- (AMKEmail *)primaryEmail;
- (void)setEmails:(NSArray<AMKEmail *> *)emails;
- (NSArray<AMKEmail *> *)emails;

- (NSDictionary*)userAsDictionary;

- (void)wipeUserData;

@end
