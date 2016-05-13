//
//  TKParserHelper.h
//  TripGo
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TKTripKit.h"

@interface TKParserHelper : STKParserHelper

#pragma mark - Segments

+ (STKTripSegmentVisibility)segmentVisibilityType:(NSString *)string;

+ (NSNumber *)segmentTypeForString:(NSString *)typeString;

#pragma mark - Services

+ (void)adjustService:(Service *)service
forRealTimeStatusString:(NSString *)realTimeStatus;

#pragma mark - Shapes

+ (NSArray<Shape *> *)insertNewShapes:(NSArray<NSDictionary *> *)shapesArray
                           forService:(Service *)service
                         withModeInfo:(ModeInfo *)modeInfo;

+ (NSArray<Shape *> *)insertNewShapes:(NSArray<NSDictionary *> *)shapesArray
                           forService:(Service *)service
                         withModeInfo:(ModeInfo *)modeInfo
                     orTripKitContext:(NSManagedObjectContext *)context;

#pragma mark - Vehicles

+ (void)updateVehiclesForService:(Service *)service
                  primaryVehicle:(NSDictionary *)primaryVehicleDict
             alternativeVehicles:(NSArray *)alternativeVehicleDicts;

+ (void)updateVehiclesForSegmentReference:(SegmentReference *)reference
                           primaryVehicle:(NSDictionary *)primaryVehicleDict
                      alternativeVehicles:(NSArray *)alternativeVehicleDicts;

#pragma mark - Stops

+ (StopLocation *)insertNewStopLocation:(NSDictionary *)stopDict
                       inTripKitContext:(NSManagedObjectContext *)context;

+ (BOOL)updateStopLocation:(StopLocation *)stop
            fromDictionary:(NSDictionary *)stopDict;

+ (SGStopCoordinate *)simpleStopFromDictionary:(NSDictionary *)stopDict;

#pragma mark - Alerts

+ (void)updateOrAddAlerts:(NSArray<NSDictionary *> *)alerts
         inTripKitContext:(NSManagedObjectContext *)context;


@end
