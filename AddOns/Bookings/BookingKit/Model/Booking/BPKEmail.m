//
//  BPKEmail.m
//  TripGo
//
//  Created by Kuan Lun Huang on 21/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKEmail.h"

static NSString *const kReceiptKey = @"receipt";

@implementation BPKEmail

#pragma mark - AMKEmail

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super initWithDictionary:dictionary];
  
  if (self) {
    _isReceipt = [[dictionary objectForKey:kReceiptKey] boolValue];
  }
  
  return self;
}

- (NSDictionary *)toDictionary
{
  NSDictionary *base = [super toDictionary];  
  NSMutableDictionary *mBase = [NSMutableDictionary dictionaryWithDictionary:base];
  [mBase setObject:@(self.isReceipt) forKey:kReceiptKey];
  
  return mBase;
}

@end
