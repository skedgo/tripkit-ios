//
//  TKTimetableDownloader.h
//  TripGo
//
//  Created by Adrian Schoenig on 7/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StopLocation, TKDLSTable;

NS_ASSUME_NONNULL_BEGIN

typedef void(^TKTimetableDownloaderCompletionBlock)(NSArray *__nullable stopVisits, NSError * __nullable error);

@interface TKTimetableDownloader : NSObject

- (void)downloadTimetableForStop:(StopLocation *)stop
                       startDate:(NSDate *)startDate
                           limit:(NSUInteger)limit
                      completion:(TKTimetableDownloaderCompletionBlock)completion;

- (void)downloadTimetableForDLSTable:(TKDLSTable *)DLSTable
                           startDate:(NSDate *)startDate
                               limit:(NSUInteger)limit
                          completion:(TKTimetableDownloaderCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
