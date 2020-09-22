//
//  TKSegmentBuilder.h
//  TripKit
//
//  Created by Adrian Schönig on 3/03/11.
//  Copyright (c) 2011 SkedGo. All rights reserved.
//

@import Foundation;
@import CoreData;
@import MapKit;

#import <TripKit/TKCrossPlatform.h>

@class TKSegment;

NS_ASSUME_NONNULL_BEGIN

@interface TKSegmentBuilder : NSObject

+ (nullable NSDictionary<NSString *, NSNumber *> *)_buildSegmentVisitsForSegment:(TKSegment *)segment;

+ (nullable NSString *)_tripSegmentModeTitleOfSegment:(TKSegment *)segment;
+ (nullable NSString *)_tripSegmentModeSubtitleOfSegment:(TKSegment *)segment;

+ (BOOL)_fillInTemplates:(NSMutableString *)string
              forSegment:(TKSegment *)segment
                 inTitle:(BOOL)title
           includingTime:(BOOL)includeTime
       includingPlatform:(BOOL)includePlatform;

+ (nullable NSString *)_buildPrimaryLocationStringForSegment:(TKSegment *)segment;

+ (NSString *)_buildSingleLineInstructionForSegment:(TKSegment *)segment
                                      includingTime:(BOOL)includeTime
                                  includingPlatform:(BOOL)includePlatform
                                    isTimeDependent:(BOOL *)isTimeDependent;

@end
NS_ASSUME_NONNULL_END
