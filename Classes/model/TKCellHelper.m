//
//  SGCellHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import "TKCellHelper.h"

#define CELLS_PER_DEGREE 75

NSString *const SGCellsClearedNotification =  @"SGCellsClearedNotification";


@implementation TKCellHelper

+ (NSSet *)identifiersForRegion:(MKCoordinateRegion)region
{
  // turn regions into identifiers
  
  // get the min and max
  int minLat = (int) ((region.center.latitude  - region.span.latitudeDelta  / 2) * CELLS_PER_DEGREE - 1);
  int minLng = (int) ((region.center.longitude - region.span.longitudeDelta / 2) * CELLS_PER_DEGREE - 1);
  int maxLat = (int) ((region.center.latitude  + region.span.latitudeDelta  / 2) * CELLS_PER_DEGREE);
  int maxLng = (int) ((region.center.longitude + region.span.longitudeDelta / 2) * CELLS_PER_DEGREE);
  
  // +1 for each as we include both ends
  int cellCount = (int) ((maxLat - minLat + 1) * (maxLng - minLng + 1));
  
  NSMutableSet *identifiers = [NSMutableSet setWithCapacity:cellCount];
  for (int lat = minLat; lat <= maxLat; lat++) {
    for (int lng = minLng; lng <= maxLng; lng++) {
      NSString *identifier = [NSString stringWithFormat:@"%d#%d", lat, lng];
      [identifiers addObject:identifier];
    }
  }
  return identifiers;
}

+ (MKCoordinateRegion)regionForIdentifier:(NSString *)identifier
{
  // turn identifier into a region
  NSArray *nums = [identifier componentsSeparatedByString:@"#"];
  ZAssert(nums.count == 2, @"Identifier needs to consist of two numbers! It doesn't: %@", identifier);
  float lat = [[nums objectAtIndex:0] floatValue];
  float lng = [[nums objectAtIndex:1] floatValue];
  
  CLLocationDegrees minLat = lat / CELLS_PER_DEGREE;
  CLLocationDegrees maxLat = (lat + 1)/CELLS_PER_DEGREE;
  CLLocationDegrees minLng = lng / CELLS_PER_DEGREE;
  CLLocationDegrees maxLng = (lng + 1)/CELLS_PER_DEGREE;
  
  CLLocationCoordinate2D center = CLLocationCoordinate2DMake((maxLat + minLat) / 2, (maxLng + minLng) / 2);
  MKCoordinateSpan span = MKCoordinateSpanMake((maxLat - minLat) / 2, (maxLng - minLng) / 2);
  
  return MKCoordinateRegionMake(center, span);
}

@end
