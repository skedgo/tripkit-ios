//
//  Geocoder.m
//  TripGo
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "SGBaseGeocoder.h"

#import "TKTripKit.h"
#import "TripKit/TripKit-Swift.h"

#import "SGAutocompletionResult.h"
#import "SGAutocompletionDataProvider.h"

@implementation SGBaseGeocoder

#pragma mark - Public methods

+ (NSError *)errorForNoLocationFoundForInput:(NSString *)input
{
  NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"'%@' not found.", @"Shared", [SGStyleManager bundle], "Error when location search for %input was not successful. (old key: RequestErrorFormat)"), input];
  return [NSError errorWithCode:kSGErrorGeocoderNothingFound
                        message:message];
}

+ (void)namedCoordinatesForAutocompletionResults:(NSArray <SGAutocompletionResult *> *)autocompletionResults
                                   usingGeocoder:(nullable id<SGGeocoder>)geocoder
                                      nearRegion:(MKMapRect)mapRect
                                      completion:(void (^)(NSArray <SGKNamedCoordinate *> *))completion
{
  NSMutableArray *coordinates = [NSMutableArray arrayWithCapacity:autocompletionResults.count];
  SGKNamedCoordinate *toGeocode = nil;
  for(SGAutocompletionResult *autocompletionResult in autocompletionResults) {
    id<SGAutocompletionDataProvider> provider = autocompletionResult.provider;
    if ([provider respondsToSelector:@selector(annotationForAutocompletionResult:)]) {
      id<MKAnnotation> annotation = [provider annotationForAutocompletionResult:autocompletionResult];
      SGKNamedCoordinate *coordinate = [SGKNamedCoordinate namedCoordinateForAnnotation:annotation];
      if (CLLocationCoordinate2DIsValid([coordinate coordinate])) {
        coordinate.sortScore = autocompletionResult.score;
        [coordinates addObject:coordinate];
        
      } else if (geocoder
                 && (!toGeocode || autocompletionResult.score > toGeocode.sortScore)) {
        SGKNamedCoordinate *namedCoordinate = [[SGKNamedCoordinate alloc] initWithName:[autocompletionResult title] address:[autocompletionResult subtitle]];
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
      NSNumber *score1 = @([(SGKNamedCoordinate *)obj1 sortScore]);
      NSNumber *score2 = @([(SGKNamedCoordinate *)obj2 sortScore]);
      if (score1 >= 0 && score2 >= 0) {
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
      NSArray<SGAutocompletionResult *> *results = [autocompleter autocompleteFast:inputString
                                                                        forMapRect:mapRect];
      [SGBaseGeocoder namedCoordinatesForAutocompletionResults:results
                                                 usingGeocoder:nil
                                                    nearRegion:mapRect
                                                    completion:
       ^(NSArray<SGKNamedCoordinate *> * _Nonnull coordinates) {
         success(inputString, coordinates);
       }];
      return;
      
    } else if ([autocompleter respondsToSelector:@selector(autocompleteSlowly:forMapRect:completion:)]) {
      [autocompleter autocompleteSlowly:inputString
                             forMapRect:mapRect
                             completion:
       ^(NSArray<SGAutocompletionResult *> *results) {
         [SGBaseGeocoder namedCoordinatesForAutocompletionResults:results
                                                    usingGeocoder:nil
                                                       nearRegion:mapRect
                                                       completion:
          ^(NSArray<SGKNamedCoordinate *> * _Nonnull coordinates) {
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
