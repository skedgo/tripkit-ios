//
//  AMKCommunicator.m
//  TripKit
//
//  Created by Brian Huang on 24/02/2015.
//
//

#import "AMKCommunicator.h"

#import "AMKAccountKit.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


static NSString *const kParameterKeyLogin     = @"username";
static NSString *const kParameterKeyPassword  = @"password";
static NSString *const kParameterKeyName      = @"name";
static NSString *const kParameterOldPassword  = @"current";
static NSString *const kParameterNewPassword  = @"new";

static NSString *const kResponseKeyUserToken        = @"userToken";
static NSString *const kResponseKeyAliases          = @"aliases";
static NSString *const kResponseKeyPasswordChanged  = @"changed";
static NSString *const kResponseKeyError            = @"error";
static NSString *const kResponseKeyUserError        = @"usererror";

static NSString *const kPathAlias     = @"account/alias";
static NSString *const kPathSignUp    = @"account/signup";
static NSString *const kPathLogin     = @"account/login";
static NSString *const kPathLogout    = @"account/logout";
static NSString *const kPathReset     = @"account/reset";
static NSString *const kPathPassword  = @"account/password";
static NSString *const kPathFacebook  = @"account/facebook";
static NSString *const kPathTwitter   = @"account/twitter";
static NSString *const kPathUser      = @"api/user";
static NSString *const kPathPhone     = @"api/user/phone";
static NSString *const kPathImage     = @"api/user/image";

@implementation AMKCommunicator

#pragma mark - Sign up, Login, Logout

- (void)signupWithName:(NSString *)name email:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setObject:email forKey:kParameterKeyLogin];
  [params setObject:password forKey:kParameterKeyPassword];

  // Name is optional
  if (name != nil) {
    [params setObject:name forKey:kParameterKeyName];
  }
  
  DLog(@"Sign up params: %@", params);
  
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:kPathSignUp
                              parameters:params
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     DLog(@"%@", responseObject);
     [AMKCommunicator findTokenInResponse:responseObject
                               completion:
      ^(NSString * _Nullable userToken, NSError * _Nullable error) {
        if (userToken) {
          handler(userToken, nil);
        } else {
          handler(email, error);
        }
      }];
   }
                                        failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(email, error);
     }
   }];
}

- (void)signInWithFacebook:(NSString *)token completion:(AMKServerBlock)handler
{ 
  // Get path.
  NSString *base = kPathFacebook;
  NSString *path = [NSString stringWithFormat:@"%@/%@", base, token];
  
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:path
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     DLog(@"%@", responseObject);
     [AMKCommunicator findTokenInResponse:responseObject
                               completion:
      ^(NSString * _Nullable userToken, NSError * _Nullable error) {
        if (userToken) {
          handler(userToken, nil);
        } else {
          handler(nil, error);
        }
      }];
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(nil, error);
     }
   }];
}

- (void)signInWithTwitter:(NSString *)token app:(SGAppIds)appId completion:(AMKServerBlock)handler
{
  NSString *providerId = [self providerIdForAppId:appId];
  
  if (providerId.length == 0) {
    ZAssert(false, @"Invalid appId for Twitter endpoint");
  }
  
  // Get path.
  NSString *base = kPathTwitter;
  NSString *path = [NSString stringWithFormat:@"%@/%@/%@/%@", base, providerId, token, @""];
  
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:path
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     DLog(@"%@", responseObject);
     [AMKCommunicator findTokenInResponse:responseObject
                               completion:
      ^(NSString * _Nullable userToken, NSError * _Nullable error) {
        if (userToken) {
          handler(userToken, nil);
        } else {
          handler(nil, error);
        }
      }];
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(nil, error);
     }
   }];
}

- (void)signInWithEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setObject:email forKey:kParameterKeyLogin];
  [params setObject:password forKey:kParameterKeyPassword];
  DLog(@"Sign up params: %@", params);
  
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:kPathLogin
                              parameters:params
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     DLog(@"%@", responseObject);
     [AMKCommunicator findTokenInResponse:responseObject
                               completion:
      ^(NSString * _Nullable userToken, NSError * _Nullable error) {
        if (userToken) {
          handler(userToken, nil);
        } else {
          handler(email, error);
        }
      }];
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(email, error);
     }
   }];
}

- (void)logout:(AMKCompletionBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:kPathLogout
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused (status, responseObject)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"Ignoring response: %@", responseObject);
     if (handler) {
       handler(nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(error);
     }
   }];
}

#pragma mark - Names

- (void)updateName:(NSString *)name completion:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"PUT"
                                    path:kPathUser
                              parameters:@{@"name": name}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"response: %@", responseObject);
     if (handler) {
       handler(name, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(name, error);
     }
   }];
}

- (void)fetchName:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"GET"
                                    path:kPathUser
                              parameters:nil
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"response: %@", responseObject);
     if ([responseObject isKindOfClass:[NSDictionary class]]) {
       NSString *name = [responseObject objectForKey:@"name"];
       if (name != nil && handler != nil) {
         handler(name, nil);
       }
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
}

- (void)updateSurname:(NSString *)surname completion:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"PUT"
                                    path:kPathUser
                              parameters:@{@"surname": surname}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"response: %@", responseObject);
     if (handler) {
       handler(surname, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(surname, error);
     }
   }];
}

- (void)fetchSurname:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"GET"
                                    path:kPathUser
                              parameters:nil
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"response: %@", responseObject);
     if ([responseObject isKindOfClass:[NSDictionary class]]) {
       NSString *surname = [responseObject objectForKey:@"surname"];
       if (handler != nil) {
         handler(surname, nil);
       }
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
}

- (void)updateGivenName:(NSString *)givenName completion:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"PUT"
                                    path:kPathUser
                              parameters:@{@"givenName": givenName}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"response: %@", responseObject);
     if (handler) {
       handler(givenName, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(givenName, error);
     }
   }];
}

- (void)fetchGivenName:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"GET"
                                    path:kPathUser
                              parameters:nil
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"response: %@", responseObject);
     if ([responseObject isKindOfClass:[NSDictionary class]]) {
       NSString *givenName = [responseObject objectForKey:@"givenName"];
       if (handler != nil) {
         handler(givenName, nil);
       }
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
}

- (void)updateSurname:(NSString *)surname givenName:(NSString *)givenName completion:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"PUT"
                                    path:kPathUser
                              parameters:@{@"surname": surname,@"givenName":givenName}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"response: %@", responseObject);
     if (handler) {
       handler(@{@"surname": surname,@"givenName":givenName}, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(@{@"surname": surname,@"givenName":givenName}, error);
     }
   }];
}

#pragma mark - Emails

- (void)fetchListOfEmails:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"GET"
                                    path:kPathAlias
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"%@", responseObject);
     NSArray *emails = [responseObject objectForKey:kResponseKeyAliases];
     if (emails != nil) {
       if (handler != nil) {
         handler(emails, nil);
       }
     } else {
       NSError *error = [NSError errorWithCode:0 message:@"Cannot find email aliases in the response"];
       if (handler != nil) {
         handler(nil, error);
       }
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
}

- (void)resendEmail:(NSString *)email completion:(AMKServerBlock)handler
{
  NSString *basePath = kPathAlias;
  NSString *path = [basePath stringByAppendingFormat:@"/%@", email];
  DLog(@"path: %@", path);
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:path
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused (status, responseObject)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"Ignoring response: %@", responseObject);
     if (handler != nil) {
       handler(email, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(email, error);
     }
   }];
}

- (void)addEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  if (password != nil) {
    [self validatePassword:password completion:^(NSError *error) {
      typeof(weakSelf) strongSelf = weakSelf;
      if (! strongSelf) return;
      
      if (! error) {
        [strongSelf registerEmail:email completion:handler];
      } else {
        if (handler != nil) {
          handler(email, error);
        }
      }
    }];
  } else {
    [self registerEmail:email completion:handler];
  }
}

- (void)removeEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  if (! password) {
    [self removeEmail:email completion:handler];
    
  } else {
    [self validatePassword:password completion:^(NSError *error) {
      typeof(weakSelf) strongSelf = weakSelf;
      if (! strongSelf) return;
      
      if (error != nil) {
        if (handler) {
          handler(email, error);
        }
      } else {
        [strongSelf removeEmail:email completion:handler];
      }
    }];
  }
}

- (void)setPrimaryEmail:(NSString *)email password:(NSString *)password completion:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  if (! password) {
    [self setPrimaryEmail:email completion:handler];
    
  } else {
    [self validatePassword:password completion:^(NSError *error) {
      typeof(weakSelf) strongSelf = weakSelf;
      if (! strongSelf) return;
      
      if (error != nil) {
        handler(email, error);
      } else {
        [strongSelf setPrimaryEmail:email completion:handler];
      }
    }];
  }
}

#pragma mark - Phone Numbers

- (void)addPhoneNumber:(NSString *)phone phoneCode:(NSString *)phoneCode type:(NSString*)type  completion:(AMKServerBlock)handler
{
  __weak typeof(self) weakSelf = self;
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setObject:phone forKey:@"phone"];
  [params setObject:phoneCode forKey:@"phoneCode"];
  [params setObject:type forKey:@"type"];
  
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:kPathPhone
                              parameters:params
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"%@", responseObject);
     
     if (responseObject != nil) {
       if (handler != nil) {
         handler(responseObject, nil);
       }
     } else {
       NSError *error = [NSError errorWithCode:0 message:@"No response"];
       if (handler != nil) {
         handler(nil, error);
       }
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
}

- (void)updatePhoneNumberWithId:(NSString*)phoneId phoneNumber:(NSString *)phone phoneCode:(NSString *)phoneCode type:(NSString*)type  completion:(AMKServerBlock)handler
{
  NSString *basePath = kPathPhone;
  NSString *path = [basePath stringByAppendingFormat:@"/%@", phoneId];
  
  __weak typeof(self) weakSelf = self;
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setObject:phone forKey:@"phone"];
  [params setObject:phoneCode forKey:@"phoneCode"];
  [params setObject:type forKey:@"type"];
  
  [self.sharedServer hitSkedGoWithMethod:@"PUT"
                                    path:path
                              parameters:params
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"%@", responseObject);
     
     if (responseObject != nil) {
       if (handler != nil) {
         handler(responseObject, nil);
       }
     } else {
       NSError *error = [NSError errorWithCode:0 message:@"No response"];
       if (handler != nil) {
         handler(nil, error);
       }
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
}

- (void)deletePhoneNumberWithId:(NSString*)phoneId completion:(AMKServerBlock)handler
{
  NSString *basePath = kPathPhone;
  NSString *path = [basePath stringByAppendingFormat:@"/%@", phoneId];
  
  __weak typeof(self) weakSelf = self;
  
  [self.sharedServer hitSkedGoWithMethod:@"DELETE"
                                    path:path
                              parameters:nil
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"%@", responseObject);
     
     if (responseObject != nil) {
       if (handler != nil) {
         handler(responseObject, nil);
       }
     } else {
       NSError *error = [NSError errorWithCode:0 message:@"No response"];
       if (handler != nil) {
         handler(nil, error);
       }
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
  
}

#pragma mark -  Images

- (void)addImage:(UIImage *)image completion:(AMKServerBlock)handler
{
  // encode the image as JPEG
  NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:kPathImage
                              parameters:nil
                              customData:imageData
                                  region:nil
                          callbackOnMain:YES
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     if (handler != nil) {
       handler(image, nil);
     }
     
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
  
}

- (void)deleteImageWithCompletion:(AMKServerBlock)handler
{
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"DELETE"
                                    path:kPathImage
                              parameters:nil
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     if (handler != nil) {
       handler(nil, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
}


#pragma mark - Password

- (void)changePasswordFrom:(NSString *)from to:(NSString *)to completion:(AMKServerBlock)handler
{
  NSString *basePath = kPathPassword;
  NSString *path = [basePath stringByAppendingString:@"/change"];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setObject:from forKey:@"password"];
  [params setObject:to forKey:@"newPassword"];
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:path
                              parameters:params
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused (status, responseObject)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"Ignoring response: %@", responseObject);
     if (handler) {
       handler(to, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(to, error);
     }
   }];
}

- (void)resetPasswordUsingEmail:(NSString *)email completion:(AMKServerBlock)handler
{
  NSString *basePath = kPathReset;
  NSString *path = [basePath stringByAppendingFormat:@"/%@", email];
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:path
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"%@", responseObject);
     if (handler) {
       handler(email, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(email, error);
     }
   }];
}

#pragma mark - update User

- (void)updateUser:(AMKUser *)user completion:(AMKServerBlock)handler{
  
  NSDictionary *params = [user userAsDictionary];
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"PUT"
                                    path:kPathUser
                              parameters:params
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused(status)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"response: %@", responseObject);
     if (handler) {
       handler(responseObject, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler != nil) {
       handler(nil, error);
     }
   }];
}

#pragma mark - Private methods

- (NSMutableDictionary *)signUpParametersWithEmail:(NSString *)email password:(NSString *)password
{
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  
  ZAssert(password.length != 0, @"Invalid password");
  [params setObject:password forKey:kParameterKeyPassword];
  
  ZAssert(email.length != 0, @"Invalid email");
  [params setObject:email forKey:kParameterKeyLogin];
  
//  NSString *name = [[AMKUser sharedUser] compositeName];
//  if (! (name.length == 0)) {
//    [params setObject:name forKey:kParameterKeyName];
//  }
  
  return params;
}

- (void)validatePassword:(NSString *)password completion:(AMKCompletionBlock)handler
{
  NSString *basePath = kPathPassword;
  NSString *path = [basePath stringByAppendingString:@"/validate"];
  
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[kParameterKeyLogin] = [AMKUser sharedUser].primaryEmail.address;
  params[kParameterKeyPassword] = password;
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:path
                              parameters:params
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused (status, responseObject)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"Ignoring response: %@", responseObject);
     if (handler) {
       handler(nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(error);
     }
   }];
}

- (void)registerEmail:(NSString *)email completion:(AMKServerBlock)handler
{
  NSString *basePath = kPathAlias;
  NSString *path = [basePath stringByAppendingFormat:@"/%@", email];
  DLog(@"path: %@", path);
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:path
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused (status, responseObject)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"Ignoring response: %@", responseObject);
     if (handler) {
       handler(email, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(email, error);
     }
   }];
}

- (void)removeEmail:(NSString *)email completion:(AMKServerBlock)handler
{
  NSString *basePath = kPathAlias;
  NSString *path = [basePath stringByAppendingFormat:@"/%@", email];
  DLog(@"path: %@", path);
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"DELETE"
                                    path:path
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused (status, responseObject)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"Ignoring response: %@", responseObject);
     if (handler) {
       handler(email, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(email, error);
     }
   }];
}

- (void)setPrimaryEmail:(NSString *)email completion:(AMKServerBlock)handler
{
  NSString *basePath = kPathAlias;
  NSString *path = [basePath stringByAppendingFormat:@"/%@?primary=%@", email, @"true"];
  DLog(@"path: %@", path);
  
  __weak typeof(self) weakSelf = self;
  [self.sharedServer hitSkedGoWithMethod:@"POST"
                                    path:path
                              parameters:@{}
                                  region:nil
                                 success:
   ^(NSInteger status, id responseObject) {
#pragma unused (status, responseObject)
     typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     DLog(@"Ignoring response: %@", responseObject);
     if (handler) {
       handler(email, nil);
     }
   }
                                 failure:
   ^(NSError *error) {
     if (handler) {
       handler(email, error);
     }
   }];
}

#pragma mark - Response parsing

+ (void)findTokenInResponse:(nullable id)response
                 completion:(void(^)(NSString * _Nullable userToken, NSError * _Nullable error))handler
{
  if (response == nil || ! [response isKindOfClass:[NSDictionary class]]) {
    NSError *error = [NSError errorWithCode:0 message:@"Invalid server response"]; // No need to translate this
    handler(nil, error);

  } else {
    // We may have user errors, so let's check that.
    SVKError *error = [SVKError errorFromJSON:response];
    if (error) {
      handler(nil, error);

    } else {
      NSString *userToken = response[kResponseKeyUserToken];
      if (userToken.length > 0) {
        handler(userToken, nil);
      } else {
        NSString *description = @"Cannot find a valid token"; // No need to translate this
        error = [SVKError errorWithCode:1301 userInfo:@{ NSLocalizedDescriptionKey: description}];
        handler(nil, error);
      }
    }
  }
}

#pragma mark - Private methods

- (NSString *)providerIdForAppId:(SGAppIds)appId
{
  switch (appId) {
    case SGAppIdTripGo:
      return @"FACEBOOK_TRIPGO";
      
    default:
      return @"";
  }
}

- (SVKServer *)sharedServer
{
  return [SVKServer sharedInstance];
}

@end
