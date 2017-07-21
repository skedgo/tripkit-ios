//
//  SGKEnums.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#ifndef TripGo_SGKEnums_h
#define TripGo_SGKEnums_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SGAppIds) {
  SGAppIdTripGo,
  SGAppIdUnknown
};

typedef NS_ENUM(NSInteger, SGTimeType) {
  SGTimeTypeLeaveASAP     = 0,
  SGTimeTypeLeaveAfter    = 1,
  SGTimeTypeArriveBefore  = 2,
  SGTimeTypeNone
};

#endif
