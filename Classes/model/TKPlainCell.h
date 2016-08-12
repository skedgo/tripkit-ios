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

NS_ASSUME_NONNULL_BEGIN

@interface TKPlainCell : NSObject

@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, copy)   NSString *regionIdentifier;
@property (nonatomic, assign) SGCellLevel level;

- (nullable NSNumber*)hashCode;

- (nullable NSDate*)lastUpdate;

- (nullable NSArray<STKModeCoordinate *>*)locations;

- (nullable NSArray<STKModeCoordinate *>*)previousLocations;

- (void)updateLocations:(NSArray<STKModeCoordinate *>*)locations hashCode:(NSNumber *)hashCode;

@end

NS_ASSUME_NONNULL_END
