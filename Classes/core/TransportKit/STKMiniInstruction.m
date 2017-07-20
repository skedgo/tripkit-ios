//
//  STKMiniInstruction.m
//  TripGo
//
//  Created by Adrian Schoenig on 8/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "STKMiniInstruction.h"

@implementation STKMiniInstruction

+ (nullable STKMiniInstruction *)miniInstructionForDictionary:(nullable NSDictionary *)dictionary
{
  if (!dictionary) {
    return nil;
  }
  
  STKMiniInstruction *mini  = [[self alloc] init];
  mini.instruction          = dictionary[@"instruction"];
  mini.mainValue            = dictionary[@"mainValue"];
  mini.detail               = dictionary[@"description"];
  return mini;
}

#pragma mark - NSCoding Protocol

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_instruction forKey:@"instruction"];
  [encoder encodeObject:_mainValue forKey:@"mainValue"];
  [encoder encodeObject:_detail forKey:@"description"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self) {
    self.instruction  = [decoder decodeObjectForKey:@"instruction"];
    self.mainValue    = [decoder decodeObjectForKey:@"mainValue"];
    self.detail       = [decoder decodeObjectForKey:@"description"];
  }
  return self;
}

@end
