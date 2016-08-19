//
//  Trip+Shareable.h
//  Pods
//
//  Created by Adrian Schoenig on 24/06/2016.
//
//

#ifndef TK_NO_FRAMEWORKS
@import TripKit;
#else
#import "Trip.h"
#endif

#import "TKShareURLProvider.h"

@interface Trip (Shareable) <SGURLShareable>

@end
