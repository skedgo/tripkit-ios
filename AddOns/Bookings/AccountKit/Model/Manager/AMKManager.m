//
//  SGUserAccountManager.m
//  WotGo
//
//  Created by Brian Huang on 11/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AMKManager.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#import <TripKitBookings/TripKitBookings-Swift.h>
#endif

#import "AMKAccountKit.h"

#import "AKFbkHelper.h"
#import "AKFbkProfile.h"


// Notifications
NSString *const AMKAccountErrorKey            = @"AMKAccountError";
NSString *const AMKRenewalFailureNotification = @"AMKRenewalFailureNotification";

@interface AMKManager ()

@property (nonatomic, strong) AMKCommunicator *communicator;

// Social
@property (nonatomic, strong) ACAccountStore *managedStore;
@property (nonatomic, strong) AKFbkHelper *fbkHelper;
@property (nonatomic, assign) BOOL isRenewingAccount;

@end

@implementation AMKManager

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _communicator = [[AMKCommunicator alloc] init];
    
    // take charge of user.
    [AMKUser sharedUser].dataSource = self;
  }
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AMKUserDataSource

- (ACAccount *)userRequestsFacebookAccount:(AMKUser *)user
{
  if (user.hasLinkedFacebook) {
    return [self.fbkHelper fbkAcccount];
  }
  
  return nil;
}

#pragma mark - Notification

- (void)accountStoreChanged:(NSNotification *)notification
{
#pragma unused (notification)
  
  [self validateSigninWithAutoRenew:YES completion:^(NSError *error) {
    if (error != nil && self->_isRenewingAccount == NO) {
      NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
      [userInfo setObject:error forKey:AMKAccountErrorKey];
      [[NSNotificationCenter defaultCenter] postNotificationName:AMKRenewalFailureNotification object:self userInfo:userInfo];
    }
  }];
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

- (void)setupWithManagedStore:(ACAccountStore *)store
{
  _managedStore = store;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(accountStoreChanged:)
                                               name:ACAccountStoreDidChangeNotification
                                             object:nil];
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

#pragma mark - Public: Social

- (void)linkWithFacebook:(AMKServerBlock)handler
{
  [self.fbkHelper link:^(NSString *oauthToken, NSError *error) {
    if (oauthToken.length != 0) {
      // Link successful, create a facebook profile
      [AMKUser sharedUser].facebookAccount = [self.fbkHelper fbkAcccount];
      
      // Pass the OAuth token to our backend.
      [self->_communicator signInWithFacebook:oauthToken completion:handler];
      
    } else {
      if (handler) {
        handler(nil, error);
      }
    }
  }];
}

- (void)validateSigninWithAutoRenew:(BOOL)autoRenew completion:(AMKCompletionBlock)completion
{
  _isRenewingAccount = autoRenew;
  
  if ([[AMKUser sharedUser] hasLinkedFacebook]) {
    [self.fbkHelper validateWithAutoRenew:autoRenew completion:^(NSError *error) {
      self->_isRenewingAccount = NO;
      if (completion) {
        completion(error);
      }
    }];
    
  } else {
    // do something else.
  }
}

#pragma mark - Update User

- (void)updateUser:(AMKUser *)user completion:(AMKServerBlock)handler{
  
  [_communicator updateUser:user completion:handler];
}

#pragma mark - Lazy accessors

- (AKFbkHelper *)fbkHelper
{
  if (! _fbkHelper) {
    ZAssert(_managedStore != nil, @"Missing account store, Perhaps setup wasn't run");
    _fbkHelper = [[AKFbkHelper alloc] initWithAccountStore:self.managedStore];
    _fbkHelper.facebookAppId = [[SGKConfig sharedInstance] facebookAppID];
    _fbkHelper.permissions = [[SGKConfig sharedInstance] facebookAppPermissions];
  }
  
  return _fbkHelper;
}

@end
