//
//  SGCellHelper.h
//  TripKit
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKCellHelper : NSObject

+ (NSSet<NSString *> *)identifiersForRegion:(MKCoordinateRegion)region;

+ (MKCoordinateRegion)regionForIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
