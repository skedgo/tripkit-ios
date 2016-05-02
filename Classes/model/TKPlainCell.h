//
//  PlainCell.h
//  TripGo
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import <Foundation/Foundation.h>

#import "SGStopCoordinate.h"
#import "TKCellHelper.h"

@interface TKPlainCell : NSObject

@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, copy)   NSString *regionIdentifier;
@property (nonatomic, strong) NSDate *lastUpdate;
@property (nonatomic, assign) SGCellLevel level;
@property (nonatomic, strong) NSNumber *hashCode;

@property (nonatomic, copy) NSArray<SGStopCoordinate *> *stops;

- (void)addStop:(SGStopCoordinate *)stop;

- (void)deleteAllStops;

@end
