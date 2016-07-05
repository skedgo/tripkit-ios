//
//  StopLocation+Shareable.h
//  Pods
//
//  Created by Adrian Schoenig on 24/06/2016.
//
//

#import <TripKit/TripKit.h>

#import "StopLocation.h"
#import "TKShareURLProvider.h"

@interface StopLocation (Shareable) <SGURLShareable>

@end
