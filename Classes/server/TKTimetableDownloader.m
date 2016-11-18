//
//  TKTimetableDownloader.m
//  TripGo
//
//  Created by Adrian Schoenig on 7/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKTimetableDownloader.h"

#import <TripKit/TKTripKit.h>
#import <TripKit/TripKit-Swift.h>

@interface TKTimetableDownloader ()

@property (nonatomic, strong) TKBuzzInfoProvider *infoProvider;
@property (nonatomic, strong) TKBuzzRealTime *realTime;

@end

@implementation TKTimetableDownloader

- (void)downloadTimetableForStop:(StopLocation *)stop
                       startDate:(NSDate *)startDate
                           limit:(NSUInteger)limit
                      completion:(TKTimetableDownloaderCompletionBlock)completion
{
  [stop clearVisits];
  
  if (!self.infoProvider) {
    self.infoProvider = [[TKBuzzInfoProvider alloc] init];
  }
  
  NSDate *dateToDownload = [startDate dateByAddingTimeInterval:-15 * 60];
  NSUInteger limitToDownload = MIN(limit + 25, limit * 2);
  
  __weak typeof(self) weakSelf = self;
  [self.infoProvider downloadDeparturesForStop:stop
                                      fromDate:dateToDownload
                                         limit:limitToDownload
                                    completion:
   ^(BOOL addedChildren) {
#pragma unused (addedChildren)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (!strongSelf) {
       return;
     }
     NSArray *stopVisits = [StopVisits fetchStopVisitsForStopLocation:stop
                                                     startingFromDate:startDate];
     [strongSelf addRealTimeDataForStopVisits:stopVisits
                                withStartDate:startDate
                                        limit:limit
                                   completion:completion];
   }
                                       failure:
   ^(NSError *error) {
     completion(nil, error);
   }];
}

- (void)downloadTimetableForDLSTable:(TKDLSTable *)DLSTable
                           startDate:(NSDate *)startDate
                               limit:(NSUInteger)limit
                          completion:(TKTimetableDownloaderCompletionBlock)completion
{
  NSMutableSet *pairIdentifiers;
  if (DLSTable.previousPairs) {
    pairIdentifiers = [NSMutableSet setWithSet:DLSTable.previousPairs];
    [DLSEntry clearEntriesWithIdentifiers:DLSTable.previousPairs
                         inTripKitContext:DLSTable.tripKitContext];
  } else {
    pairIdentifiers = [NSMutableSet set];
    [DLSEntry clearAllEntriesInTripKitContext:DLSTable.tripKitContext]; // wipe all to avoid duplicates
  }
  
  if (!self.infoProvider) {
    self.infoProvider = [[TKBuzzInfoProvider alloc] init];
  }
  
  NSDate *dateToDownload = [startDate dateByAddingTimeInterval:-15 * 60];
  NSUInteger limitToDownload = limit + 25;
  
  __weak typeof(self) weakSelf = self;
  [self.infoProvider downloadDeparturesForDLSTable:DLSTable
                                          fromDate:dateToDownload
                                             limit:limitToDownload
                                        completion:
   ^(NSSet *fetchedPairIdentifiers) {
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (!strongSelf) {
       return;
     }
     [pairIdentifiers unionSet:fetchedPairIdentifiers];
     NSArray *stopVisits = [DLSEntry fetchDLSEntriesPairs:pairIdentifiers
                                                 fromDate:dateToDownload
                                                    limit:limitToDownload
                                         inTripKitContext:DLSTable.tripKitContext];

     [strongSelf addRealTimeDataForStopVisits:stopVisits
                                withStartDate:startDate
                                        limit:limit
                                   completion:completion];
   }
                                       failure:
   ^(NSError *error) {
     completion(nil, error);
   }];
  
}

#pragma mark - Private: Real-time data

- (void)addRealTimeDataForStopVisits:(NSArray *)visits
                       withStartDate:(NSDate *)startDate
                               limit:(NSUInteger)limit
                          completion:(TKTimetableDownloaderCompletionBlock)completion
{
  if (visits.count == 0) {
    // TODO: add error
    completion(nil, nil);
    return;
  }
  
  NSMutableArray *realTimeVisits = [NSMutableArray arrayWithCapacity:visits.count];
  for (StopVisits *visit in visits) {
    if (visit.service.isRealTimeCapable) {
      [realTimeVisits addObject:visit];
    }
  }
  
  if (realTimeVisits.count == 0) {
    NSArray *filtered = [self filteredVisits:visits
                                forStartDate:startDate
                                       limit:limit
                                        sort:NO];
    completion(filtered, nil);
    
  } else {
    StopVisits *firstVisit = [realTimeVisits firstObject];
    SVKRegion *region = [firstVisit regionForRealTimeUpdates];
    if (!self.realTime) {
      self.realTime = [[TKBuzzRealTime alloc] init];
    }
    __weak typeof(self) weakSelf = self;
    [self.realTime updateEmbarkations:[NSSet setWithArray:realTimeVisits]
                             inRegion:region
                              success:
     ^(NSSet *embarkations) {
#pragma unused(embarkations)
       __strong typeof(weakSelf) strongSelf = weakSelf;
       if (!strongSelf) {
         return;
       }

       NSArray *filtered = [strongSelf filteredVisits:visits
                                         forStartDate:startDate
                                                limit:limit
                                                 sort:YES];
       completion(filtered, nil);
     }
                         failure:
     ^(NSError *error) {
       __strong typeof(weakSelf) strongSelf = weakSelf;
       if (!strongSelf) {
         return;
       }
       
       [SGKLog info:@"TimetableDownloader" block:^NSString * _Nonnull{
         return [NSString stringWithFormat:@"Real-time update failed: %@", error];
       }];
       NSArray *filtered = [strongSelf filteredVisits:visits
                                         forStartDate:startDate
                                                limit:limit
                                                 sort:NO];
       completion(filtered, nil); // no need to pass on error, we got stops
     }];
  }
}

- (NSArray *)filteredVisits:(NSArray *)visits
               forStartDate:(NSDate *)startDate
                      limit:(NSUInteger)limit
                       sort:(BOOL)sort
{
  NSArray *filtered = [visits filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"departure >= %@", startDate]];
  if (sort) {
    filtered = [filtered sortedArrayUsingDescriptors:[StopVisits defaultSortDescriptors]];
  }
  if (filtered.count > limit) {
    filtered = [filtered subarrayWithRange:NSMakeRange(0, limit)];
  }
  return filtered;
}

@end
