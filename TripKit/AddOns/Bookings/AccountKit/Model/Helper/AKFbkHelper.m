//
//  AMKFacebookHelper.m
//  TripKit
//
//  Created by Kuan Lun Huang on 13/03/2015.
//
//

#import "AKFbkHelper.h"

#import "AMKAccountErrorHelper.h"

@interface AKFbkHelper ()

@property (nonatomic, strong) ACAccountStore *accountStore;

@property (nonatomic, copy) NSString *oldOauthToken;
@property (nonatomic, strong) AMKAccountErrorHelper *errorHelper;

@end

@implementation AKFbkHelper

- (instancetype)initWithAccountStore:(ACAccountStore *)store
{
  self = [self init];
  
  if (self) {
    _accountStore = store;
    _errorHelper = [[AMKAccountErrorHelper alloc] initWithAccountType:[self fbkAccountType]];
  }
  
  return self;
}

- (void)link:(AMKLinkFacebookCompletionBlock)completion
{
  DLog(@"Attemping to link with Facebook");
  
  [_accountStore requestAccessToAccountsWithType:[self fbkAccountType]
                                        options:[self fbkAccessOptions]
                                     completion:
   ^(BOOL granted, NSError *error) {
     NSError *customError;
     
     if (! granted) {
       if (! error) {
         customError = [self->_errorHelper accessDeniedError];
       } else {
         customError = [self customErrorForError:error];
       }
     }
     
     if (completion) {
       completion([self fbkOauthToken], customError);
     }
   }];
}

- (void)renew:(void (^)(NSError *))completion
{
  _oldOauthToken = [self fbkOauthToken];
  
  [_accountStore renewCredentialsForAccount:[self fbkAcccount]
                                completion:
   ^(ACAccountCredentialRenewResult renewResult, NSError *error) {
     switch (renewResult) {
       case ACAccountCredentialRenewResultRenewed:
       {
         if (completion) {
           completion(nil);
         }
         break;
       }
         
       case ACAccountCredentialRenewResultRejected:
       {
         if (completion) {
           completion([self customErrorForError:error]);
         }
         break;
       }
         
       case ACAccountCredentialRenewResultFailed:
       {
         if (completion) {
           completion([self customErrorForError:error]);
         }
         break;
       }
         
      default:
         break;
     }
   }];
}

- (void)validateWithAutoRenew:(BOOL)renew completion:(void (^)(NSError *))completion
{
  NSError *error;
  
  if (! [self fbkAcccount]) { // no account found
    error = [_errorHelper accountNotFoundError];
    if (completion) {
      completion(error);
    }
    
  } else if (! [self fbkOauthToken]) { // token became invalid
    if (renew) {
      [self renew:^(NSError *renewError) {
        if (completion) {
          completion(renewError);
        }
      }];
      
    } else {
      error = [_errorHelper credentialError];
      if (completion) {
        completion(error);
      }
    }
    
  } else { // account exist and token valid.
    DLog(@"Facebook account is still valid");
    if (completion) {
      completion(nil);
    }
  }
}

- (ACAccount *)fbkAcccount
{
  return [[_accountStore accountsWithAccountType:[self fbkAccountType]] lastObject];
}

#pragma mark - Private: Others

- (ACAccountType *)fbkAccountType
{
  return [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
}

- (NSString *)fbkOauthToken
{
  return [self fbkAcccount].credential.oauthToken;
}

#pragma mark - Private: Errors

- (NSError *)customErrorForError:(NSError *)error
{
  NSInteger code = error.code;
  NSString *description = error.localizedDescription;
  
  if (code == 1) {
    if ([description rangeOfString:@"190"].location != NSNotFound) {
      return [_errorHelper credentialError];
      
    } else {
      return error;
    }
    
  } else if (code == 6) {
    return [_errorHelper accountNotFoundError];
    
  } else {
    return error;
    
  }
}

#pragma mark - Private: Access requests

- (NSDictionary *)fbkAccessOptions
{
  ZAssert(self.facebookAppId != nil, @"We need a facebook app id to proceed");
  
  if (self.permissions.count == 0) {
    // This is the mandaory permission setting.
    self.permissions = @[@"public_profile"];
  }
  
  NSMutableDictionary *options = [NSMutableDictionary dictionary];
  
  [options setValue:[self facebookAppId] forKey:ACFacebookAppIdKey];
  [options setValue:[self permissions] forKey:ACFacebookPermissionsKey];
  [options setValue:ACFacebookAudienceFriends forKey:ACFacebookAudienceKey];
  
  return options;
}

@end
