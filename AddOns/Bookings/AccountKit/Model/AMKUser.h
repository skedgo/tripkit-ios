//
//  AMKUser.h
//  TripGo
//
//  Created by Kuan Lun Huang on 9/02/2015.
//
//

#import <Foundation/Foundation.h>

#import "AMKEmail.h"

#import "AKFbkProfile.h"

static NSString *const kAMKFirstNameUserDefaultsKey   = @"AMK.Defaults.firstName";
static NSString *const kAMKLastNameUserDefaultsKey    = @"AMK.Defaults.lastName";
static NSString *const kAMKEmailsUserDefaultsKey      = @"AMK.Defaults.emails";
static NSString *const kAMKNameUserDefaultsKey        = @"AMK.Defaults.name";
static NSString *const kAMKAppDataUserDefaultsKey     = @"AMK.Defaults.appData";

// User defaults: Social accounts
static NSString *const kAMKFbkLinkedUserDefaultsKey  = @"AMK.Defaults.Linked.Facebook";
static NSString *const kAMKTwtLinkedUserDefaultsKey  = @"AMK.Defaults.Linked.Twitter";

@protocol AMKUserDataSource;

@interface AMKUser : NSObject

@property (nonatomic, weak) id<AMKUserDataSource> dataSource;

// Basic info
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSDictionary *appData;

// Social stuff
@property (nonatomic, strong) ACAccount *facebookAccount;
@property (nonatomic, strong, readonly) AKFbkProfile *facebookProfile;

+ (AMKUser *)sharedUser;

- (NSString *)compositeName;
- (BOOL)hasSignedUp;

- (AMKEmail *)primaryEmail;
- (void)setEmails:(NSArray<AMKEmail *> *)emails;
- (NSArray<AMKEmail *> *)emails;

- (BOOL)hasLinkedFacebook;
- (BOOL)hasLinkedTwitter;

- (NSDictionary*)userAsDictionary;

- (void)wipeUserData;
- (void)unlinkFacebook:(BOOL)unlink;
- (void)unlinkTwitter:(BOOL)unlink;
- (void)unlinkSocialAccounts:(BOOL)unlink;

@end

@protocol AMKUserDataSource <NSObject>

- (ACAccount *)userRequestsFacebookAccount:(AMKUser *)user;

@end
