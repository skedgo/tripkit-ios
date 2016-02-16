//
//  SGKConfig+TKInterAppCommunicator.h
//  TripGo
//
//  Created by Adrian Schoenig on 11/08/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "SGKConfig.h"

@interface SGKConfig (TKInterAppCommunicator)

/**
 @return Something like 'tripgo'
 */
- (nullable NSString *)gocatchReferralCode;

/**
 @return Something like 'ingogo a Taxi ($5 credit^)'
 */
- (nullable NSString *)ingogoCouponPrompt;

/**
 @return Something like 'TGS1'
 */
- (nullable NSString *)ingogoCouponCode;

/**
 @return Something like 'TripGo'
 */
- (nullable NSString *)sidecarReferralCode;

/**
 @return something like 'tripgo://?resume=true&x-source=TripGo'
 */
- (nullable NSString *)googleMapsCallback;

/**
 @return something like 'skedgo'
 */
- (nullable NSString *)lyftPartnerCompanyName;

@end
