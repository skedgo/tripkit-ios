//
//  SGKGrouping.h
//  TripKit
//
//  Created by Adrian Schoenig on 20/02/2014.
//
//

#ifndef TripKit_SGKGrouping_h
#define TripKit_SGKGrouping_h

typedef NS_ENUM(NSInteger, SGKGrouping) {
	SGKGrouping_Start,
	SGKGrouping_Middle,
	SGKGrouping_End,
	SGKGrouping_Individual, // start + middle + end in one
	SGKGrouping_EdgeToEdge, // item should go edge-to-edge, so grouping is irrelevant
};

#endif
