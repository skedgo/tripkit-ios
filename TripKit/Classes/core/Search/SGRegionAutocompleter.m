//
//  SGRegionAutocompleter.m
//  TripKit
//
//  Created by Adrian Schoenig on 25/02/2015.
//
//

#import "SGRegionAutocompleter.h"

#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"


#import "SGAutocompletionResult.h"

@interface SGRegionAutocompleter ()

@property (nonatomic, strong) NSArray *allAutocompletionResults;

@end

@implementation SGRegionAutocompleter

#pragma mark - SGAutocompletionDataProvider

- (NSArray *)autocompleteFast:(NSString *)string forMapRect:(MKMapRect)mapRect
{
  NSArray *allRegions = [TKRegionManager.shared regions];
  
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:allRegions.count];
  for (SGAutocompletionResult *result in self.allAutocompletionResults) {
    
    BOOL matches = NO;
    if (string.length > 0) {
      if ([result.title rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound) {
        matches = YES;
      } else if (result.subtitle && [result.subtitle rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound) {
        matches = YES;
      }
      
    } else {
      matches = YES; // everything matches empty strings
    }
    
    if (matches) {
      // score it
      SVKRegionCity *annotation = result.object;
      NSUInteger rawScore = [SGAutocompletionResult scoreBasedOnDistanceFromCoordinate:[annotation coordinate]
                                                                              toRegion:MKCoordinateRegionForMapRect(mapRect)
                                                                          longDistance:YES];
      result.score = [SGAutocompletionResult rangedScoreForScore:rawScore
                                                  betweenMinimum:50
                                                      andMaximum:90];
      
      // add it
      [array addObject:result];
    }
  }
  return array;
}

- (id<MKAnnotation>)annotationForAutocompletionResult:(SGAutocompletionResult *)result
{
  SVKRegionCity *center = result.object;
  return center;
}

#pragma mark - Lazy accessors

- (NSArray *)allAutocompletionResults
{
  if (! _allAutocompletionResults) {
    NSArray *allRegions = [TKRegionManager.shared regions];
    
    SGKImage *image = [SGAutocompletionResult imageForType:SGAutocompletionSearchIconCity];

    NSMutableArray *autocompletionResults = [NSMutableArray arrayWithCapacity:allRegions.count];
    for (SVKRegion *region in allRegions) {
      for (SVKRegionCity *centerAnnotation in region.cities) {
        SGAutocompletionResult *result = [[SGAutocompletionResult alloc] init];
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
