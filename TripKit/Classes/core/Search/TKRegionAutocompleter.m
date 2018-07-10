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

#pragma mark - SGAutocompletionDataProvider

- (NSArray *)autocompleteFast:(NSString *)string forMapRect:(MKMapRect)mapRect
{
  NSArray *allRegions = [TKRegionManager.shared regions];
  
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:allRegions.count];
  for (TKAutocompletionResult *result in self.allAutocompletionResults) {
    
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
      TKRegionCity *annotation = result.object;
      NSUInteger rawScore = [TKAutocompletionResult scoreBasedOnDistanceFromCoordinate:[annotation coordinate]
                                                                              toRegion:MKCoordinateRegionForMapRect(mapRect)
                                                                          longDistance:YES];
      result.score = [TKAutocompletionResult rangedScoreForScore:rawScore
                                                  betweenMinimum:50
                                                      andMaximum:90];
      
      // add it
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
