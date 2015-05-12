//
//  DLSTable.h
//  TripGo
//
//  Created by Adrian Schoenig on 27/05/2014.
//
//

#import <CoreData/CoreData.h>

@class SVKRegion;

NS_ASSUME_NONNULL_BEGIN

@interface TKDLSTable : NSObject

- (instancetype)initWithStartStopCode:(NSString *)startStopCode
                          endStopCode:(NSString *)endStopCode
                    withPreviousPairs:(nullable NSSet *)previousPairs
                             inRegion:(SVKRegion *)region
                    forTripKitContext:(NSManagedObjectContext *)context;

@property (nonatomic, copy, readonly) NSString *startStopCode;
@property (nonatomic, copy, readonly) NSString *endStopCode;
@property (nonatomic, strong, readonly, nullable) NSSet *previousPairs;
@property (nonatomic, strong, readonly) SVKRegion *region;
@property (nonatomic, strong, readonly) NSManagedObjectContext *tripKitContext;

@end

NS_ASSUME_NONNULL_END
