//
//  TKParserHelper.h
//  TripKit
//
//  Created by Adrian Schoenig on 7/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

@import Foundation;
@import CoreData;


@class Service, Shape, SegmentReference, StopLocation, ModeInfo;

@interface TKParserHelper : NSObject

#pragma mark - Segments

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

+ (void)updateVehiclesForSegmentReference:(SegmentReference *)reference
                           primaryVehicle:(NSDictionary *)primaryVehicleDict
                      alternativeVehicles:(NSArray *)alternativeVehicleDicts;

@end
