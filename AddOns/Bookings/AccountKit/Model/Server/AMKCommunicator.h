//
//  AMKCommunicator.h
//  TripKit
//
//  Created by Brian Huang on 24/02/2015.
//
//

#import <Foundation/Foundation.h>

#ifdef TK_NO_MODULE
#import "SGKEnums.h"
#import "SGKCrossPlatform.h"
#else
@import TripKit;
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^AMKServerBlock)(id _Nullable object,  NSError * _Nullable error);
typedef void (^AMKCompletionBlock)(NSError * _Nullable error);

@class AMKUser;

@interface AMKCommunicator : NSObject

- (void)signupWithName:(NSString *)name email:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;
- (void)signInWithEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;
- (void)signInWithFacebook:(NSString *)token completion:(AMKServerBlock)handler;
- (void)signInWithTwitter:(NSString *)token app:(SGAppIds)appId completion:(AMKServerBlock)handler;
- (void)logout:(AMKCompletionBlock)handler;

- (void)updateName:(NSString *)name completion:(AMKServerBlock)handler;
- (void)fetchName:(AMKServerBlock)handler;
- (void)updateSurname:(NSString *)surname completion:(AMKServerBlock)handler;
- (void)fetchSurname:(AMKServerBlock)handler;
- (void)updateGivenName:(NSString *)givenName completion:(AMKServerBlock)handler;
- (void)fetchGivenName:(AMKServerBlock)handler;
- (void)updateSurname:(NSString *)surname givenName:(NSString *)givenName completion:(AMKServerBlock)handler;

- (void)fetchListOfEmails:(AMKServerBlock)handler;
- (void)resendEmail:(NSString *)email completion:(AMKServerBlock)handler;
- (void)addEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;
- (void)removeEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;
- (void)setPrimaryEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler;

- (void)addPhoneNumber:(NSString *)phone phoneCode:(NSString *)phoneCode type:(NSString*)type  completion:(AMKServerBlock)handler;
- (void)updatePhoneNumberWithId:(NSString*)phoneId phoneNumber:(NSString *)phone phoneCode:(NSString *)phoneCode type:(NSString*)type  completion:(AMKServerBlock)handler;
- (void)deletePhoneNumberWithId:(NSString*)phoneId completion:(AMKServerBlock)handler;

- (void)addImage:(SGKImage *)image completion:(AMKServerBlock)handler;
- (void)deleteImageWithCompletion:(AMKServerBlock)handler;

- (void)changePasswordFrom:(NSString *)from to:(NSString *)to completion:(AMKServerBlock)handler;
- (void)resetPasswordUsingEmail:(NSString *)email completion:(AMKServerBlock)handler;

- (void)updateUser:(AMKUser *)user completion:(AMKServerBlock)handler;

+ (void)findTokenInResponse:(nullable id)response
                 completion:(void(^)(NSString * _Nullable userToken, NSError * _Nullable error))handler;

@end

NS_ASSUME_NONNULL_END
