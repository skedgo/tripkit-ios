//
//  SGStopLocation.h
//  TripGo
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import <Foundation/Foundation.h>

#import "STKMapAnnotation.h"
#import "ModeInfo.h"

@protocol TKStopAnnotation <STKDisplayablePoint>

- (NSString *)stopCode;
- (ModeInfo *)stopModeInfo;

@end
