//
//  SGKConfig+TKInterAppCommunicator.m
//  TripGo
//
//  Created by Adrian Schoenig on 11/08/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "SGKConfig+TKInterAppCommunicator.h"

@implementation SGKConfig (TKInterAppCommunicator)

- (nullable NSString *)flitWaysPartnerKey
{
  return self.configuration[@"TKInterAppCommunicator"][@"flitWaysPartnerKey"];
}

- (nullable NSString *)gocatchReferralCode
{
  return self.configuration[@"TKInterAppCommunicator"][@"gocatchReferralCode"];
}

- (nullable NSString *)googleMapsCallback
{
  return self.configuration[@"TKInterAppCommunicator"][@"googleMapsCallback"];
}

- (nullable NSString *)lyftPartnerCompanyName
{
  NSString *proper = self.configuration[@"TKInterAppCommunicator"][@"lyftPartnerCompanyName"];
  if (proper) {
    return proper;
  }
  
  // fall-back for old, bad name
  return self.configuration[@"TKInterAppCommunicator"][@"yelpPartnerCompanyName"];
}


@end
