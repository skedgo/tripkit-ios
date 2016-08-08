//
//  PlainCell.h
//  TripGo
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

@import Foundation;
@import SGCoreKit;

#import "TKCellHelper.h"

@interface TKPlainCell : NSObject

@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, copy)   NSString *regionIdentifier;
@property (nonatomic, strong) NSDate *lastUpdate;
@property (nonatomic, assign) SGCellLevel level;
@property (nonatomic, strong) NSNumber *hashCode;

@property (nonatomic, copy) NSArray<STKStopCoordinate *> *stops;

- (void)addStop:(STKStopCoordinate *)stop;

- (void)deleteAllStops;

@end
