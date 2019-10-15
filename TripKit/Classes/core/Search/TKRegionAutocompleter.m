//
//  TKRegionAutocompleter.m
//  TripKit
//
//  Created by Adrian Schoenig on 25/02/2015.
//
//

#import "TKRegionAutocompleter.h"

#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"


#import "TKAutocompletionResult.h"

@interface TKRegionAutocompleter ()

@property (nonatomic, strong) NSArray *allAutocompletionResults;

@end

@implementation TKRegionAutocompleter

#pragma mark - SGDeprecatedAutocompletionDataProvider

- (NSArray *)autocompleteFast:(NSString *)string forMapRect:(MKMapRect)mapRect
{
  NSArray *allRegions = [TKRegionManager.shared regions];
  
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:allRegions.count];
  for (TKAutocompletionResult *result in self.allAutocompletionResults) {
    
    NSUInteger titleScore;
    if (string.length > 0) {
      titleScore = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:string candidate:result.title];
    } else {
      titleScore = 100; // everything matches empty strings
    }
    
    if (titleScore > 0) {
      TKRegionCity *annotation = result.object;
      
      NSUInteger distanceScore = [TKAutocompletionResult scoreBasedOnDistanceFromCoordinate:annotation.coordinate
                                                                              toRegion:MKCoordinateRegionForMapRect(mapRect)
                                                                          longDistance:YES];
      
      NSUInteger rawScore = (titleScore * 9 + distanceScore) / 10l;
      
      result.score = [TKAutocompletionResult rangedScoreForScore:rawScore
                                                  betweenMinimum:10
                                                      andMaximum:70];
      
      [array addObject:result];
    }
  }
  return array;
}

- (id<MKAnnotation>)annotationForAutocompletionResult:(TKAutocompletionResult *)result
{
  TKRegionCity *center = result.object;
  return center;
}

#pragma mark - Lazy accessors

- (NSArray *)allAutocompletionResults
{
  if (! _allAutocompletionResults) {
    NSArray *allRegions = [TKRegionManager.shared regions];
    
    TKImage *image = [TKAutocompletionResult imageForType:TKAutocompletionSearchIconCity];

    NSMutableArray *autocompletionResults = [NSMutableArray arrayWithCapacity:allRegions.count];
    for (TKRegion *region in allRegions) {
      for (TKRegionCity *centerAnnotation in region.cities) {
        TKAutocompletionResult *result = [[TKAutocompletionResult alloc] init];
        result.object = centerAnnotation;
        result.title  = centerAnnotation.title;
        result.image  = image;
        result.provider = self;
        result.isInSupportedRegion = @(YES);
        [autocompletionResults addObject:result];
      }
    }
    _allAutocompletionResults = autocompletionResults;
  }
  return _allAutocompletionResults;
}

@end
