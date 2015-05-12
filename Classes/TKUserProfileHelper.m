//
//  TKUserProfileHelper.m
//  TripGo
//
//  Created by Adrian Schoenig on 2/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKUserProfileHelper.h"

#import "TKTripKit.h"

@implementation TKUserProfileHelper

+ (void)updateTransportModesWithEnabledOrder:(NSArray *)enabled
                                   minimized:(NSSet *)minimized
                                      hidden:(NSSet *)hidden
{
  NSUserDefaults *shared = [NSUserDefaults sharedDefaults];
  if (enabled) {
    [shared setObject:enabled forKey:TKDefaultsKeyProfileSortedModeIdentifiers];
  }
  if (minimized) {
    [shared setObject:[minimized allObjects] forKey:TKDefaultsKeyProfileMinimizedModeIdentifiers];
  }
  if (hidden) {
    [shared setObject:[hidden allObjects] forKey:TKDefaultsKeyProfileHiddenModeIdentifiers];
  }
}

+ (void)toggleMinimizedStateOfModeIdentifier:(NSString *)modeIdentifier
{
  
  NSMutableSet *minimized = [NSMutableSet setWithSet:[self minimizedModeIdentifiers]];
  if ([minimized containsObject:modeIdentifier]) {
    [minimized removeObject:modeIdentifier];
  } else {
    [minimized addObject:modeIdentifier];
  }
  [[NSUserDefaults sharedDefaults] setObject:minimized forKey:TKDefaultsKeyProfileMinimizedModeIdentifiers];
}

+ (NSArray *)orderedEnabledModeIdentifiersForAvailableModeIdentifiers:(NSArray *)available
{
  NSMutableArray *orderedEnabled = [NSMutableArray arrayWithArray:available];
  NSSet *hidden = [self hiddenModeIdentifiers];
  [orderedEnabled removeObjectsInArray:[hidden allObjects]];
  
  NSArray *sorted = [[NSUserDefaults sharedDefaults] objectForKey:TKDefaultsKeyProfileSortedModeIdentifiers];
  if (sorted) {
    [orderedEnabled sortUsingComparator:^NSComparisonResult(NSString *first, NSString *second) {
      NSInteger firstIndexInSorted = [sorted indexOfObject:first];
      NSInteger secondIndexInSorted = [sorted indexOfObject:second];
      if (firstIndexInSorted == NSNotFound
          || secondIndexInSorted == NSNotFound
          || firstIndexInSorted < secondIndexInSorted) {
        return NSOrderedAscending;
      } else if (firstIndexInSorted == secondIndexInSorted) {
        return NSOrderedSame;
      } else {
        return NSOrderedDescending;
      }
    }];
  }
  
  return orderedEnabled;
}

+ (NSSet *)minimizedModeIdentifiers
{
  NSArray *minimizedArray = [[NSUserDefaults sharedDefaults] objectForKey:TKDefaultsKeyProfileMinimizedModeIdentifiers];
  if (minimizedArray) {
    return [NSSet setWithArray:minimizedArray];
  } else {
    // defaults
    return [NSSet setWithObjects:SVKTransportModeIdentifierMotorbike, SVKTransportModeIdentifierWalking, nil];
  }
}

+ (NSSet *)hiddenModeIdentifiers
{
  NSArray *hiddenArray = [[NSUserDefaults sharedDefaults] objectForKey:TKDefaultsKeyProfileHiddenModeIdentifiers];
  if (hiddenArray) {
    return [NSSet setWithArray:hiddenArray];
  } else {
    return [NSSet set];
  }
}

@end
