//
//  SGUserAccountManager.m
//  TripKit
//
//  Created by Brian Huang on 11/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AMKManager.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#import <TripKitBookings/TripKitBookings-Swift.h>
#endif

#import "AMKAccountKit.h"


// Notifications
NSString *const AMKAccountErrorKey            = @"AMKAccountError";
NSString *const AMKRenewalFailureNotification = @"AMKRenewalFailureNotification";

@interface AMKManager ()

@property (nonatomic, strong) AMKCommunicator *communicator;

@end

@implementation AMKManager

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _communicator = [[AMKCommunicator alloc] init];
  }
  
  return self;
}

#pragma mark - Public: Setup

+ (AMKManager *)sharedInstance
{
  static AMKManager *_manager;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _manager = [[self alloc] init];
  });
  
  return _manager;
}

#pragma mark - Public: Sign out and sign in

- (void)signupWithName:(id)name email:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  [_communicator signupWithName:name email:email password:password completion:handler];
}

- (void)signinWithEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  [_communicator signInWithEmail:email password:password completion:handler];
}

- (void)signout:(AMKCompletionBlock)handler
{
  [_communicator logout:^(NSError *error) {
    // Always wipe data even if there was en error (e.g., the user is offline)
    [[AMKUser sharedUser] wipeUserData];
    
    if (handler) {
      handler(error);
    }
  }];
}

#pragma mark - Public: Names

- (void)updateName:(NSString *)fullName completion:(AMKServerBlock)handler
{
  [_communicator updateName:fullName completion:handler];
}

- (void)fetchName:(AMKServerBlock)handler
{
  [_communicator fetchName:handler];
}

- (void)updateSurname:(NSString *)surname completion:(AMKServerBlock)handler
{
  [_communicator updateSurname:surname completion:handler];
}

- (void)fetchSurname:(AMKServerBlock)handler
{
  [_communicator fetchSurname:handler];
}

- (void)updateGivenName:(NSString *)givenName completion:(AMKServerBlock)handler
{
  [_communicator updateGivenName:givenName completion:handler];
}

- (void)fetchGivenName:(AMKServerBlock)handler
{
  [_communicator fetchGivenName:handler];
}

- (void)updateSurname:(NSString *)surname givenName:(NSString *)givenName completion:(AMKServerBlock)handler
{
  [_communicator updateSurname:surname givenName:givenName completion:handler];
}

#pragma mark - Public: Emails

- (void)fetchListOfEmails:(AMKServerBlock)handler
{
  [_communicator fetchListOfEmails:handler];
}

- (void)sendVerificationToEmail:(NSString *)email completion:(AMKServerBlock)handler
{
  [_communicator resendEmail:email completion:handler];
}

- (void)addEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  [_communicator addEmail:email password:password completion:handler];
}

- (void)removeEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  [_communicator removeEmail:email password:password completion:handler];
}

- (void)markEmailAsPrimary:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  [_communicator setPrimaryEmail:email password:password completion:handler];
}

#pragma mark - Public: Phone Numbers

- (void)addPhoneNumber:(NSString *)phone phoneCode:(NSString *)phoneCode type:(NSString*)type completion:(AMKServerBlock)handler
{
  [_communicator addPhoneNumber:phone phoneCode:phoneCode type:type completion:handler];
}

- (void)updatePhoneNumberWithId:(NSString*)phoneId phoneNumber:(NSString *)phone phoneCode:(NSString *)phoneCode type:(NSString*)type  completion:(AMKServerBlock)handler
{
  [_communicator updatePhoneNumberWithId:phoneId phoneNumber:phone phoneCode:phoneCode type:type completion:handler];
}

- (void)deletePhoneNumberWithId:(NSString*)phoneId completion:(AMKServerBlock)handler
{
  [_communicator deletePhoneNumberWithId:phoneId completion:handler];
}

#pragma mark - Public: Images

- (void)addImage:(UIImage *)image completion:(AMKServerBlock)handler
{
  [_communicator addImage:image completion:handler];
}

- (void)deleteImageWithCompletion:(AMKServerBlock)handler
{
  [_communicator deleteImageWithCompletion:handler];
}

#pragma mark - Public: Password

- (void)changePasswordFrom:(NSString *)old to:(NSString *)new completion:(AMKServerBlock)handler
{
  [_communicator changePasswordFrom:old to:new completion:handler];
}

- (void)resetPassword:(AMKServerBlock)handler
{
  NSString *primaryEmail = [[AMKUser sharedUser] primaryEmail].address;
  if (primaryEmail != nil) {
    [_communicator resetPasswordUsingEmail:primaryEmail completion:handler];
  }
}

#pragma mark - Update User

- (void)updateUser:(AMKUser *)user completion:(AMKServerBlock)handler{
  
  [_communicator updateUser:user completion:handler];
}

@end
