//
//  SGKConfig+TKInterAppCommunicator.m
//  TripKit
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
  return self.configuration[@"TKInterAppCommunicator"][@"lyftPartnerCompanyName"];
}

- (nullable NSString *)olaXAPPToken
{
  return self.configuration[@"TKInterAppCommunicator"][@"olaXAPPToken"];
}

@end
