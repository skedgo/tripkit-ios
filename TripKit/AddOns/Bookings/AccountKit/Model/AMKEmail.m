//
//  AMKEmail.m
//  TripKit
//
//  Created by Kuan Lun Huang on 9/02/2015.
//
//

#import "AMKEmail.h"

static NSString *const kEmailKey    = @"email";
static NSString *const kPrimaryKey  = @"primary";
static NSString *const kVerifiedKey = @"verified";

@interface AMKEmail ()

@end

@implementation AMKEmail

- (instancetype)initWithAddress:(NSString *)address isPrimary:(BOOL)primary isVerified:(BOOL)verified
{
  self = [self init];
  
  if (self) {
    _address = address;
    _isPrimary = primary;
    _isVerified = verified;
  }
  
  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [self init];
  
  if (self) {
    _address = [dictionary objectForKey:kEmailKey];
    _isPrimary = [[dictionary objectForKey:kPrimaryKey] boolValue];
    _isVerified = [[dictionary objectForKey:kVerifiedKey] boolValue];
  }
  
  return self;
}

- (NSDictionary *)toDictionary
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  
  [dictionary setObject:_address ?: @"" forKey:kEmailKey];
  [dictionary setObject:@(_isPrimary) forKey:kPrimaryKey];
  [dictionary setObject:@(_isVerified) forKey:kVerifiedKey];
  
  return dictionary;
}

#pragma mark - Overrides

- (NSString *)description
{
  return [NSString stringWithFormat:@"Address: %@, Primary: %@, Verified: %@", _address, @(_isPrimary), @(_isVerified)];
}

@end
