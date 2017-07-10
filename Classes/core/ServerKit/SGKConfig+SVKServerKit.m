//
//  SGKConfig+SVKServerKit.m
//  TripGo
//
//  Created by Adrian Schoenig on 14/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "SGKConfig+SVKServerKit.h"

#import "SGKBetaHelper.h"

@implementation SGKConfig (SVKServerKit)

- (NSString *)regionEligibility
{
  if ([SGKBetaHelper isBeta]) {
    NSString *betaEligibility = self.configuration[@"BetaRegionEligibility"];
    if (betaEligibility.length > 0) {
      return betaEligibility;
    }
  }

  NSString *regionEligibility = self.configuration[@"RegionEligibility"];
  return regionEligibility;
}

@end
