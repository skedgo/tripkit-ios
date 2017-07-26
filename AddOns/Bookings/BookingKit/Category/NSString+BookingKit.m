//
//  NSString+BookingKit.m
//  TripKit
//
//  Created by Kuan Lun Huang on 9/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "NSString+BookingKit.h"

@implementation NSString (BookingKit)

- (NSString *)removeTrailingNewLine
{
  NSRange range = NSMakeRange(self.length - 1, 1);
  NSString *result = [self stringByReplacingOccurrencesOfString:@"\n" withString:@"" options:NSBackwardsSearch range:range];
  return result;
}

@end
