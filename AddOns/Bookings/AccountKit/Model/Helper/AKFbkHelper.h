//
//  AMKFacebookHelper.h
//  TripKit
//
//  Created by Kuan Lun Huang on 13/03/2015.
//
//

@import Accounts;

#ifndef TK_NO_FRAMEWORKS

#endif

typedef void (^AMKLinkFacebookCompletionBlock)(NSString *oauthToken, NSError *error);

@interface AKFbkHelper : NSObject

@property (nonatomic, copy) NSString *facebookAppId;
@property (nonatomic, copy) NSArray *permissions;

- (instancetype)initWithAccountStore:(ACAccountStore *)store;

- (void)link:(AMKLinkFacebookCompletionBlock)completion;

- (void)renew:(void(^)(NSError *))completion;

- (void)validateWithAutoRenew:(BOOL)renew completion:(void(^)(NSError *))completion;

- (ACAccount *)fbkAcccount;

@end
