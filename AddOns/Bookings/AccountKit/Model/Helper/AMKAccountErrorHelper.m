//
//  AMKErrorHelper.m
//  TripKit
//
//  Created by Kuan Lun Huang on 17/03/2015.
//
//

#import "AMKAccountErrorHelper.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


#import "AMKUser.h"

@interface AMKAccountErrorHelper ()

@property (nonatomic, strong) ACAccountType *accountType;

@end

@implementation AMKAccountErrorHelper

- (instancetype)initWithAccountType:(ACAccountType *)type
{
  self = [self init];
  
  if (self) {
    _accountType = type;
  }
  
  return self;
}

- (NSError *)credentialError
{
  NSString *format = @"Unable to renew %@ account. Please make sure you have provided the correct password by going to Settings -> %@.";
  NSString *message = [NSString stringWithFormat:format, [self accountDescription], [self accountDescription]];
  return [NSError errorWithCode:1 message:message];
}

- (NSError *)accessDeniedError
{
  NSString *format = @"Access to %@ is not available. Please make sure you have allowed %@ to access your %@ account by going to Settings -> %@ -> %@.";
  NSString *message = [NSString stringWithFormat:format, [self accountDescription], [self productName], [self accountDescription], [self accountDescription], [self productName]];
  NSError *error = [NSError errorWithCode:7 message:message];
  return error;
}

- (NSError *)accountNotFoundError
{
  NSString *format;
  NSString *message;
  
  BOOL linked = NO;
  
  if ([self isAccountTypeFacebook]) {
    linked = [[AMKUser sharedUser] hasLinkedFacebook];
  }
  
  if (linked) {
    format = @"%@ account not found. It may have been removed from Settings.";
    message = [NSString stringWithFormat:format, [self accountDescription]];
    
  } else {
    format = @"%@ account has not been set up. Please go to Settings -> %@ to set it up.";
    message = [NSString stringWithFormat:format, [self accountDescription], [self accountDescription]];
    
  }
  
  return [NSError errorWithCode:6 message:message];
}

#pragma mark - Private methods

- (NSString *)accountDescription
{
  if ([self isAccountTypeFacebook]) {
    return @"Facebook";
    
  } else if ([self isAccountTypeTwitter]) {
    return @"Twitter";
    
  } else {
    return nil;
  }
}

- (BOOL)isAccountTypeFacebook
{
  return [_accountType.identifier isEqualToString:ACAccountTypeIdentifierFacebook];
}

- (BOOL)isAccountTypeTwitter
{
  return [_accountType.identifier isEqualToString:ACAccountTypeIdentifierTwitter];
}

- (NSString *)productName
{
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  return info[@"CFBundleDisplayName"];
}

@end
