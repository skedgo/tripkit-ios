//
//  AMKUser.m
//  TripKit
//
//  Created by Kuan Lun Huang on 9/02/2015.
//
//

#import "AMKUser.h"

#import "NSString+ValidateEmailAddress.h"

#import "SVKServerKit.h"

@implementation AMKUser

#pragma mark - Public methods

+ (AMKUser *)sharedUser
{
  static AMKUser *_user;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _user = [[self alloc] init];
  });
  
  return _user;
}

- (NSString *)compositeName
{
  if (self.name.length != 0) {
    return self.name;
  }
  
  NSMutableString *composite = [NSMutableString stringWithString:@""];
  
  if (! (self.firstName.length == 0)) {
    [composite appendString:self.firstName];
  }
  
  if (! (self.lastName.length == 0)) {
    if (! (self.firstName.length == 0)) {
      [composite appendString:@" "];
    }
    [composite appendString:self.lastName];
  }
  
  return composite;
}

- (BOOL)hasSignedUp
{
  return self.token.length != 0;
}

- (AMKEmail *)primaryEmail
{
  AMKEmail *primary;
  
  NSArray *allEmails = [self emails];
  
  for (AMKEmail *email in allEmails) {
    if (email.isPrimary) {
      primary = email;
      break;
    }
  }
  
  if (! primary && allEmails.count > 0) {
    primary = [[self emails] firstObject];
  }
  
  return primary;
}

- (void)setEmails:(NSArray *)emails
{
  NSMutableArray *dictionaries = [NSMutableArray arrayWithCapacity:emails.count];
  
  for (AMKEmail *email in emails) {
    [dictionaries addObject:[email toDictionary]];
  }
  
  [[NSUserDefaults sharedDefaults] setObject:dictionaries forKey:kAMKEmailsUserDefaultsKey];
}

- (NSArray *)emails
{
  NSMutableArray *amkEmails = [NSMutableArray array];
  
  NSArray *emails = [[NSUserDefaults sharedDefaults] objectForKey:kAMKEmailsUserDefaultsKey];
  
  for (NSDictionary *anEmail in emails) {
    AMKEmail *amkEmail = [[AMKEmail alloc] initWithDictionary:anEmail];
    [amkEmails addObject:amkEmail];
  }
  
  return amkEmails;
}

- (NSDictionary*)userAsDictionary{
  return @{@"givenName"     : self.firstName,
           @"surname"    : self.lastName,
           @"appData" : self.appData};
}

- (void)wipeUserData
{
  [self setFirstName:nil];
  [self setLastName:nil];
  [self setEmails:nil];
  [self setToken:nil];
  [self setName:nil];
}

#pragma mark - Overrides

- (NSString *)description
{
  NSString *format = @"\n\tFirst: %@\n\tLast: %@\n\tName: %@\n\tToken: %@\n\tEmails: %@\n\tAppData: %@";
  return [NSString stringWithFormat:format, self.firstName, self.lastName, self.name, self.token, self.emails, self.appData];
}

#pragma mark - Custom accessors

- (NSString *)firstName
{
  return [[NSUserDefaults sharedDefaults] objectForKey:kAMKFirstNameUserDefaultsKey];
}

- (void)setFirstName:(NSString *)firstName
{
  [[NSUserDefaults sharedDefaults] setObject:firstName forKey:kAMKFirstNameUserDefaultsKey];
}

- (NSString *)lastName
{
  return [[NSUserDefaults sharedDefaults] objectForKey:kAMKLastNameUserDefaultsKey];
}

- (void)setLastName:(NSString *)lastName
{
  [[NSUserDefaults sharedDefaults] setObject:lastName forKey:kAMKLastNameUserDefaultsKey];
}

- (NSString *)name
{
  return [[NSUserDefaults sharedDefaults] objectForKey:kAMKNameUserDefaultsKey];
}

- (void)setName:(NSString *)name
{
  [[NSUserDefaults sharedDefaults] setObject:name forKey:kAMKNameUserDefaultsKey];
}

- (NSString *)token
{
  return [SVKServer userToken];
}

- (void)setToken:(NSString *)token
{
  [SVKServer updateUserToken:token];
}

- (NSDictionary *)appData
{
  return [[NSUserDefaults sharedDefaults] objectForKey:kAMKAppDataUserDefaultsKey];
}

- (void)setAppData:(NSDictionary *)appData
{
  [[NSUserDefaults sharedDefaults] setObject:appData forKey:kAMKAppDataUserDefaultsKey];
}



@end
