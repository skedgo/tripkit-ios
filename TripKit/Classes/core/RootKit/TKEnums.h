//
//  TKEnums.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#ifndef TripKit_TKEnums_h
#define TripKit_TKEnums_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TKTimeType) {
  TKTimeTypeLeaveASAP     = 0,
  TKTimeTypeLeaveAfter    = 1,
  TKTimeTypeArriveBefore  = 2,
  TKTimeTypeNone
};

typedef NS_ENUM(NSInteger, TKGrouping) {
  TKGrouping_Start,
  TKGrouping_Middle,
  TKGrouping_End,
  TKGrouping_Individual, // start + middle + end in one
  TKGrouping_EdgeToEdge, // item should go edge-to-edge, so grouping is irrelevant
};

#endif
