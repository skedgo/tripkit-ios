//
//  SGRealTimeUpdatableHelper.h
//  TripGo
//
//  Created by Adrian Schoenig on 16/01/2015.
//
//

#import <Foundation/Foundation.h>

@interface TKRealTimeUpdatableHelper : NSObject

+ (BOOL)wantsRealTimeUpdatesForStart:(NSDate *)start
                              andEnd:(NSDate *)end
                      forPreplanning:(BOOL)forPreplanning;

@end
