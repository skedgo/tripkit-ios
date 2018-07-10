//
//  Geocoder.m
//  TripKit
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKBaseGeocoder.h"

#import "TKTripKit.h"
#import "TripKit/TripKit-Swift.h"

#import "TKAutocompletionResult.h"
#import "SGAutocompletionDataProvider.h"

@implementation TKBaseGeocoder

#pragma mark - Public methods

+ (NSError *)errorForNoLocationFoundForInput:(NSString *)input
{
  NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"'%@' not found.", @"Shared", [TKStyleManager bundle], "Error when location search for %input was not successful. (old key: RequestErrorFormat)"), input];
  return [NSError errorWithCode:kSGErrorGeocoderNothingFound
                        message:message];
}

+ (void)namedCoordinatesForAutocompletionResults:(NSArray <TKAutocompletionResult *> *)autocompletionResults
                                   usingGeocoder:(nullable id<SGGeocoder>)geocoder
                                      nearRegion:(MKMapRect)mapRect
                                      completion:(void (^)(NSArray <TKNamedCoordinate *> *))completion
{
  NSMutableArray *coordinates = [NSMutableArray arrayWithCapacity:autocompletionResults.count];
  TKNamedCoordinate *toGeocode = nil;
  for(TKAutocompletionResult *autocompletionResult in autocompletionResults) {
    id<SGAutocompletionDataProvider> provider = autocompletionResult.provider;
    if ([provider respondsToSelector:@selector(annotationForAutocompletionResult:)]) {
      id<MKAnnotation> annotation = [provider annotationForAutocompletionResult:autocompletionResult];
      TKNamedCoordinate *coordinate = [TKNamedCoordinate namedCoordinateForAnnotation:annotation];
      if (CLLocationCoordinate2DIsValid([coordinate coordinate])) {
        coordinate.sortScore = autocompletionResult.score;
        [coordinates addObject:coordinate];
        
      } else if (geocoder
                 && (!toGeocode || autocompletionResult.score > toGeocode.sortScore)) {
        TKNamedCoordinate *namedCoordinate = [[TKNamedCoordinate alloc] initWithName:[autocompletionResult title] address:[autocompletionResult subtitle]];
        namedCoordinate.sortScore = autocompletionResult.score;
        toGeocode = namedCoordinate;
      }
    }
  }
  
  if (!toGeocode) {
    completion(coordinates);
  } else {
    [self geocodeObject:toGeocode
          usingGeocoder:geocoder
             nearRegion:mapRect
             completion:
     ^(BOOL success) {
       if (success) {
         [coordinates addObject:toGeocode];
       }
       completion(coordinates);
    }];
  }
}

+ (id<MKAnnotation>)pickBestFromResults:(NSArray <id<MKAnnotation>> *)results
{
  if (1 == results.count) {
    return [results firstObject];
  }
  
  NSArray *sorted = [results sortedArrayUsingComparator:^NSComparisonResult(id<MKAnnotation> obj1, id<MKAnnotation> obj2) {
    if ([obj1 respondsToSelector:@selector(sortScore)]
        && [obj2 respondsToSelector:@selector(sortScore)]) {
      NSNumber *score1 = @([(TKNamedCoordinate *)obj1 sortScore]);
      NSNumber *score2 = @([(TKNamedCoordinate *)obj2 sortScore]);
      if (score1.integerValue >= 0 && score2.integerValue >= 0) {
        return [score2 compare:score1];
      }
    }
    return NSOrderedSame;
  }];
  return [sorted firstObject];
}

#pragma mark - SGGeocoder

- (void)geocodeString:(NSString *)inputString
           nearRegion:(MKMapRect)mapRect
              success:(SGGeocoderSuccessBlock)success
              failure:(nullable SGGeocoderFailureBlock)failure
{
#pragma unused(failure)
  
  if ([self conformsToProtocol:@protocol(SGAutocompletionDataProvider)]) {
    id<SGAutocompletionDataProvider> autocompleter = (id<SGAutocompletionDataProvider>)self;
    
    if ([autocompleter respondsToSelector:@selector(autocompleteFast:forMapRect:)]) {
      NSArray<TKAutocompletionResult *> *results = [autocompleter autocompleteFast:inputString
                                                                        forMapRect:mapRect];
      [TKBaseGeocoder namedCoordinatesForAutocompletionResults:results
                                                 usingGeocoder:nil
                                                    nearRegion:mapRect
                                                    completion:
       ^(NSArray<TKNamedCoordinate *> * _Nonnull coordinates) {
         success(inputString, coordinates);
       }];
      return;
      
    } else if ([autocompleter respondsToSelector:@selector(autocompleteSlowly:forMapRect:completion:)]) {
      [autocompleter autocompleteSlowly:inputString
                             forMapRect:mapRect
                             completion:
       ^(NSArray<TKAutocompletionResult *> *results) {
         [TKBaseGeocoder namedCoordinatesForAutocompletionResults:results
                                                    usingGeocoder:nil
                                                       nearRegion:mapRect
                                                       completion:
          ^(NSArray<TKNamedCoordinate *> * _Nonnull coordinates) {
            success(inputString, coordinates);
          }];
       }];
      return;
    }
    
  }
  

  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this save method"
                                          userInfo:nil];
  [ex raise];
}



@end
