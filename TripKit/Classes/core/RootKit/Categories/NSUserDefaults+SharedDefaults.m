//
//  NSUserDefaults+SharedDefaults.m
//  TripKit
//
//  Created by Kuan Lun Huang on 30/12/2014.
//
//

#import "NSUserDefaults+SharedDefaults.h"

#import "TKConfig.h"
#import "TripKit/TripKit-Swift.h"

@implementation NSUserDefaults (SharedDefaults)

+ (NSUserDefaults *)sharedDefaults
{
  static NSUserDefaults *_sharedDefaults = nil;
  
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    _sharedDefaults = [[self alloc] initWithSuiteName:[[TKConfig sharedInstance] appGroupName]];
  });
  
  return _sharedDefaults;
}

@end
