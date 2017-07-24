//
//  SGCellHelper.h
//  TripKit
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import <MapKit/MapKit.h>

typedef enum {
  SGCellLevelUnknown = 0,
  SGCellLevelRegion  = 1,
  SGCellLevelLocal   = 50,
} SGCellLevel;

FOUNDATION_EXPORT NSString *const SGCellsClearedNotification;


@interface TKCellHelper : NSObject

+ (NSSet *)identifiersForRegion:(MKCoordinateRegion)region;

+ (MKCoordinateRegion)regionForIdentifier:(NSString *)identifier;


@end
