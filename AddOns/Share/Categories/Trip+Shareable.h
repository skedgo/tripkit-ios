//
//  Trip+Shareable.h
//  Pods
//
//  Created by Adrian Schoenig on 24/06/2016.
//
//

#import <TripKit/TripKit.h>

#import "TKShareURLProvider.h"
#import "Trip.h"

@interface Trip (Shareable) <SGURLShareable>

@end
