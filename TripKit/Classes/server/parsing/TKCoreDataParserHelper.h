//
//  TKCoreDataParserHelper.h
//  TripKit
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

@import Foundation;
@import CoreData;

NS_ASSUME_NONNULL_BEGIN

@class Service, Shape, SegmentReference, TKModeInfo;

@interface TKCoreDataParserHelper : NSObject

#pragma mark - Services

+ (void)adjustService:(Service *)service
forRealTimeStatusString:(nullable NSString *)realTimeStatus;

#pragma mark - Shapes

+ (NSArray<Shape *> *)insertNewShapes:(NSArray<NSDictionary<NSString *, id> *> *)shapesArray
                           forService:(Service *)service
                         withModeInfo:(nullable TKModeInfo *)modeInfo
                        clearRealTime:(BOOL)clearRealTime;

+ (NSArray<Shape *> *)insertNewShapes:(NSArray<NSDictionary<NSString *, id> *> *)shapesArray
                           forService:(nullable Service *)service
                         withModeInfo:(nullable TKModeInfo *)modeInfo
                     orTripKitContext:(nullable NSManagedObjectContext *)context
                        clearRealTime:(BOOL)clearRealTime;

#pragma mark - Vehicles

+ (void)updateVehiclesForSegmentReference:(SegmentReference *)reference
                           primaryVehicle:(nullable NSDictionary<NSString *, id> *)primaryVehicleDict
                      alternativeVehicles:(nullable NSArray<NSDictionary<NSString *, id> *> *)alternativeVehicleDicts;

@end

NS_ASSUME_NONNULL_END
