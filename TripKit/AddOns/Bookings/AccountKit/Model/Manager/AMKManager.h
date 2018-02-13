//
//  SGUserAccountManager.h
//  TripKit
//
//  Created by Brian Huang on 11/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Accounts/Accounts.h>

#import "AMKUser.h"
#import "AMKCommunicator.h"

// Notifications
FOUNDATION_EXPORT NSString *const AMKAccountErrorKey;
FOUNDATION_EXPORT NSString *const AMKRenewalFailureNotification;

@interface AMKManager : NSObject <AMKUserDataSource>

+ (AMKManager *)sharedInstance;

// Setup
- (void)setupWithManagedStore:(ACAccountStore *)store;

// Sign up and sign in
- (void)signupWithName:(NSString *)name email:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;
- (void)signinWithEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;
- (void)signout:(AMKCompletionBlock)handler;

// Names
- (void)updateName:(NSString *)fullName completion:(AMKServerBlock)handler;
- (void)fetchName:(AMKServerBlock)handler;
- (void)updateSurname:(NSString *)surname completion:(AMKServerBlock)handler;
- (void)fetchSurname:(AMKServerBlock)handler;
- (void)updateGivenName:(NSString *)givenName completion:(AMKServerBlock)handler;
- (void)fetchGivenName:(AMKServerBlock)handler;
- (void)updateSurname:(NSString *)surname givenName:(NSString *)givenName completion:(AMKServerBlock)handler;

// Emails
- (void)fetchListOfEmails:(AMKServerBlock)handler;
- (void)sendVerificationToEmail:(NSString *)email completion:(AMKServerBlock)handler;
- (void)addEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;
- (void)removeEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;
- (void)markEmailAsPrimary:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;

// Phone Numbers

- (void)addPhoneNumber:(NSString *)phone phoneCode:(NSString *)phoneCode type:(NSString*)type  completion:(AMKServerBlock)handler;
- (void)updatePhoneNumberWithId:(NSString*)phoneId phoneNumber:(NSString *)phone phoneCode:(NSString *)phoneCode type:(NSString*)type  completion:(AMKServerBlock)handler;
- (void)deletePhoneNumberWithId:(NSString*)phoneId completion:(AMKServerBlock)handler;

// Images

- (void)addImage:(UIImage *)image completion:(AMKServerBlock)handler;
- (void)deleteImageWithCompletion:(AMKServerBlock)handler;

// Password
- (void)changePasswordFrom:(NSString *)from to:(NSString *)to completion:(AMKServerBlock)handler;
- (void)resetPassword:(AMKServerBlock)handler;

// Social accounts
- (void)linkWithFacebook:(AMKServerBlock)handler;
- (void)validateSigninWithAutoRenew:(BOOL)autoRenew completion:(AMKCompletionBlock)completion;


// Update AMKUser

- (void)updateUser:(AMKUser *)user completion:(AMKServerBlock)handler;

@end
