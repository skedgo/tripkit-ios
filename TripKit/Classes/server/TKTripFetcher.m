//
//  TKTripFetcher.m
//  TripKit
//
//  Created by Adrian Schönig on 2/03/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "TKTripFetcher.h"

#import <TripKit/TripKit-Swift.h>

#import "TKTransportModes.h"
#import "TripRequest.h"


@implementation TKTripFetcher

#pragma mark - Public interface

- (void)downloadTrip:(NSURL *)url
  intoTripKitContext:(NSManagedObjectContext *)tripKitContext
          completion:(void(^)(Trip * __nullable trip))completion
{
  [self downloadTrip:url identifier:nil intoTripKitContext:tripKitContext completion:completion];
}

- (void)downloadTrip:(NSURL *)url
          identifier:(nullable NSString *)identifier
  intoTripKitContext:(NSManagedObjectContext *)tripKitContext
          completion:(void(^)(Trip * __nullable trip))completion
{
  if (!identifier) {
    NSUInteger hash = [[url absoluteString] hash];
    identifier = [NSString stringWithFormat:@"%lu", (unsigned long) hash];
  }
  
  TKFileCacheDirectory directory = TKFileCacheDirectoryDocuments;

  void (^withJSON)(id, NSURL * _Nullable) = ^void(id JSON, NSURL * _Nullable shareURL) {
    [self parseJSON:JSON forTripKitContext:tripKitContext completion:
     ^(Trip *trip) {
       if (shareURL) {
         trip.shareURL = shareURL;
       }
       trip.request.expandForFavorite = YES;
       if (completion) {
         completion(trip);
       }
     }];
  };
  
  [self hitURLForTripDownload:url includeStops:YES completion:
   ^(NSURL *shareURL, id JSON, NSError *error) {
     if (JSON) {
       [TKJSONCache save:identifier dictionary:JSON directory:directory subdirectory:nil];
       withJSON(JSON, shareURL);
       
     } else {
       NSDictionary *JSON = [TKJSONCache read:identifier directory:directory];
       if (JSON) {
         withJSON(JSON, nil);
       } else {
         
         // failure
         [TKLog info:NSStringFromClass([self class]) text:[NSString stringWithFormat:@"Failed to download trip, and no copy in cache. Error: %@", error]];
         if (completion) {
           completion(nil);
         }
       }
     }
    }];
}

- (void)updateTrip:(Trip *)trip completionWithFlag:(void(^)(Trip *trip, BOOL tripUpdated))completion
{
  NSURL *updateURL = [NSURL URLWithString:trip.updateURLString];
  if (updateURL == nil) {
    [TKLog info:@"TKRouter" text:[NSString stringWithFormat:@"Tried to update a trip that doesn't have a (valid) update URL: %@", trip]];
    completion(trip, NO);
    return;
  }
  
  [self hitURLForTripDownload:updateURL includeStops:NO completion:^(NSURL *shareURL, id JSON, NSError *error) {
#pragma unused(shareURL)
    if (JSON) {
      [self parseJSON:JSON updatingTrip:trip completion:^(Trip * _Nullable updatedTrip) {
        [TKLog debug:NSStringFromClass([self class]) block:^NSString * _Nonnull{
          __block NSString *result = nil;
          [updatedTrip.managedObjectContext performBlockAndWait:^{
            result = [NSString stringWithFormat:@"Updated trip (%ld): %@", (long)updatedTrip.tripGroup.visibility, [updatedTrip debugString]];
          }];
          return result;
        }];
        if (completion) {
          if (updatedTrip != nil) {
            completion(updatedTrip, YES);
          } else {
            completion(trip, NO);
          }
        }
      }];
    } else if (! error) {
      // No new data (but also no error)
      if (completion) {
        completion(trip, NO);
      }
    }
  }];
}

- (void)updateTrip:(Trip *)trip completion:(void(^)(Trip *trip))completion
{
    [self updateTrip:trip completionWithFlag:^(Trip *updatedTrip, BOOL tripGotUpdated) {
#pragma unused(tripGotUpdated)
        completion(updatedTrip);
    }];
}

- (void)updateTrip:(Trip *)trip
           fromURL:(NSURL *)URL
           aborter:(nullable BOOL(^)(NSURL *URL))aborter
        completion:(void(^)(NSURL *URL, Trip * __nullable trip, NSError * __nullable error))completion
{
  [self hitURLForTripDownload:URL
                 includeStops:NO
                   completion:
   ^(NSURL *shareURL, id JSON, NSError *error) {
#pragma unused(shareURL)
    if (JSON) {
      if (aborter && aborter(URL)) {
        return;
      }
      
      [self parseJSON:JSON
         updatingTrip:trip
           completion:
       ^(Trip *updatedTrip) {
         completion(URL, updatedTrip, nil);
      }];
    } else {
      completion(URL, nil, error);
    }
  }];
}


#pragma mark - Private methods

- (void)hitURLForTripDownload:(NSURL *)url
                 includeStops:(BOOL)includeStops
                   completion:(void (^)(NSURL *shareURL, id JSON, NSError *error))completion
{
  NSURL *baseURL;
  if ([url.scheme isEqualToString:@"file"]) {
    baseURL = url;
    
  } else {
    // de-construct the URL
    NSString *port = nil != url.port ? [NSString stringWithFormat:@":%@", url.port] : @"";
    NSString *scheme = [url.scheme hasPrefix:@"http"] ? url.scheme : @"https"; // keep http and https, but replace stuff like $appname://
    NSString *baseURLString = [NSString stringWithFormat:@"%@://%@%@%@", scheme, url.host, port, url.path];
    baseURL = [NSURL URLWithString:baseURLString];
  }
  
  // use our default parameters and append those from the URL
  NSMutableDictionary *paras = [NSMutableDictionary dictionaryWithDictionary:[TKSettings config]];
  NSString *query = url.query;
  for (NSString *option in [query componentsSeparatedByString:@"&"]) {
    NSArray *pair = [option componentsSeparatedByString:@"="];
    if (pair.count == 1) {
      [paras setValue:@(YES) forKey:pair[0]];
    } else if (pair.count == 2) {
      [paras setValue:pair[1] forKey:pair[0]];
    }
  }
  
  if (includeStops) {
    [paras setValue:@(YES) forKey:@"includeStops"];
  }
  
  // Hit it
  [TKServer GET:baseURL paras:paras completion:
   ^(NSInteger status, NSDictionary<NSString *,id> *headers, id  _Nullable responseObject, NSData *data, NSError * _Nullable error) {
#pragma unused(status, headers, data)
     completion(baseURL, responseObject, error);
   }];
}

- (void)parseJSON:(id)json
     updatingTrip:(Trip *)trip
       completion:(void(^)(Trip * __nullable trip))completion
{
  NSString *error = [json objectForKey:@"error"];
  if (error) {
    if (completion) {
      completion(nil);
    }
    return;
  }
  
  NSManagedObjectContext *tripKitContext = trip.managedObjectContext;
  TKRoutingParser *parser = [[TKRoutingParser alloc] initWithTripKitContext:tripKitContext];
  [parser parseJSON:json
       updatingTrip:trip
         completion:
   ^(Trip *updatedTrip) {
     if (updatedTrip) {
       ZAssert(updatedTrip.managedObjectContext == tripKitContext, @"Context mismatch.");
       ZAssert(updatedTrip == trip, @"Trip object shouldn't have changed");
       NSError *publicError = nil;
       BOOL publicSuccess = [tripKitContext save:&publicError];
       ZAssert(publicSuccess, @"Error saving: %@", publicError);
       
       completion(updatedTrip);
     } else {
       // failure
       completion(nil);
     }
   }];
}

- (void)parseJSON:(id)json
forTripKitContext:(NSManagedObjectContext *)tripKitContext
       completion:(void(^)(Trip * __nullable trip))completion
{
  NSString *error = [json objectForKey:@"error"];
  if (error) {
    if (completion) {
      completion(nil);
    }
    return;
  }
  
  // parse it
  TKRoutingParser *parser = [[TKRoutingParser alloc] initWithTripKitContext:tripKitContext];
  [parser parseAndAddResult:json
                 completion:
   ^(TripRequest *request) {
     if (!request) {
       completion(nil);
       return;
     }
     
     // make sure we save
     ZAssert(request.managedObjectContext == tripKitContext, @"Context mismatch.");
     NSError *publicError = nil;
     BOOL publicSuccess = [tripKitContext save:&publicError];
     ZAssert(publicSuccess, @"Error saving: %@", publicError);
     
     request.lastSelection = [request.tripGroups anyObject];
     [request.lastSelection adjustVisibleTrip];
     completion(request.preferredTrip);
   }];
}


@end
