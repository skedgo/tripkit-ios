//
//  TripRequest+Shareable.h
//  Pods
//
//  Created by Adrian Schoenig on 24/06/2016.
//
//

#import <TripKit/TripKit.h>

#import "TripRequest.h"
#import "TKShareURLProvider.h"

@interface TripRequest (Shareable) <SGURLShareable>

@end
