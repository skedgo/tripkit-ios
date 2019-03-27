//
//  MKOverlay+NSCoding.m
//  TripGo
//
//  Created by Adrian Schoenig on 15/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

@import Foundation;
@import MapKit;

@implementation MKPolygon (NSCoding)

- (void)encodeWithCoder:(NSCoder *)encoder
{
  CLLocationCoordinate2D coords[self.pointCount];
  [self getCoordinates:coords range:NSMakeRange(0, self.pointCount)];

  NSMutableArray *pointArray = [NSMutableArray arrayWithCapacity:self.pointCount];
  for (NSUInteger i = 0; i < self.pointCount; i++) {
    CLLocationCoordinate2D coordinate = coords[i];
    [pointArray addObject:@{
                            @"lat": @(coordinate.latitude),
                            @"lng": @(coordinate.longitude),
                            }];
  }
  [encoder encodeObject:pointArray forKey:@"coordinates"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  NSArray *pointArray = [decoder decodeObjectForKey:@"coordinates"];
  CLLocationCoordinate2D coords[pointArray.count];
  for (NSUInteger i = 0; i < pointArray.count; i++) {
    NSDictionary *encoded = pointArray[i];
    coords[i] = CLLocationCoordinate2DMake([encoded[@"lat"] doubleValue], [encoded[@"lng"] doubleValue]);
  }
  
  self = [MKPolygon polygonWithCoordinates:coords count:pointArray.count];
  if (self) {
  }
  return self;
}

@end
