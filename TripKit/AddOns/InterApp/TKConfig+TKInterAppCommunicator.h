//
//  TKConfig+TKInterAppCommunicator.h
//  TripKit
//
//  Created by Adrian Schoenig on 11/08/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#ifdef TK_NO_MODULE
#import "TKConfig.h"
#else
@import TripKit;
#endif

@interface TKConfig (TKInterAppCommunicator)

/**
 @return Some complex API Key
 */
- (nullable NSString *)flitWaysPartnerKey;

/**
 @return Something like 'tripgo'
 */
- (nullable NSString *)gocatchReferralCode;

/**
 @return something like 'tripgo://?resume=true&x-source=TripGo'
 */
- (nullable NSString *)googleMapsCallback;

/**
 @return something like 'skedgo'
 */
- (nullable NSString *)lyftPartnerCompanyName;

/**
 @return Ola's XAPP token
 */
- (nullable NSString *)olaXAPPToken;

@end
