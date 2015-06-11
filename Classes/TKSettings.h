//
//  TKSettings.h
//  TripGo
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKSettings : NSObject

+ (NSMutableDictionary *)defaultDictionary;

+ (void)setMaximumWalkingDuration:(NSTimeInterval)duration;

@end
