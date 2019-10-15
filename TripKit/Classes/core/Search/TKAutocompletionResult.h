//
//  AutocompletionResult.h
//  TripKit
//
//  Created by Adrian Schoenig on 23/10/2013.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "TKCrossPlatform.h"

typedef NS_ENUM(NSInteger, TKAutocompletionSearchIcon) {
	TKAutocompletionSearchIconCalendar,
	TKAutocompletionSearchIconCity,
	TKAutocompletionSearchIconContact,
	TKAutocompletionSearchIconCurrentLocation,
	TKAutocompletionSearchIconFavourite,
	TKAutocompletionSearchIconHistory,
	TKAutocompletionSearchIconPin,
};

NS_ASSUME_NONNULL_BEGIN

@interface TKAutocompletionResult : NSObject

+ (TKImage *)imageForType:(TKAutocompletionSearchIcon)type;

+ (NSUInteger)scoreBasedOnDistanceFromCoordinate:(CLLocationCoordinate2D)coordinate
                                        toRegion:(MKCoordinateRegion)coordinateRegion
                                    longDistance:(BOOL)longDistance;

/**
 0:   not match, e.g., we're missing a word
 25:  same words but wrong order
 33:  has all target words but missing a completed one
 50:  matches somewhere in the word
 66:  contains all words in right order
 75:  matches start of word in search term (but starts don't match)
 100: exact match at start
 */

+ (NSUInteger)scoreBasedOnNameMatchBetweenSearchTerm:(NSString *)searchTerm
                                           candidate:(NSString *)candidate;

+ (NSUInteger)rangedScoreForScore:(NSUInteger)score
                   betweenMinimum:(NSUInteger)minimum
                       andMaximum:(NSUInteger)maximum;

+ (NSString *)stringForScoringOfString:(NSString *)string;

@property (nonatomic, weak, nullable) id provider;
@property (nonatomic, strong) id object;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *subtitle;
@property (nonatomic, strong) TKImage *image;
@property (nonatomic, strong, nullable) TKImage *accessoryButtonImage;

@property (nonatomic, strong, nullable) NSNumber *isInSupportedRegion;

/**
 A score of how this result should be ranked between 0 and 100
 
 0: probably not a good result
 25: matches only in secondary information
 50: an average match
 75: an good result matching the user input well
 100: this gotta be what the user wanted!
 */
@property (nonatomic, assign) NSInteger score;

- (NSComparisonResult)compare:(TKAutocompletionResult *)other;

@end

NS_ASSUME_NONNULL_END
