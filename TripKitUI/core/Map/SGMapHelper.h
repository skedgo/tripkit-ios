//
//  SGMapHelper.h
//  TripGo
//
//  Created by Adrian Schoenig on 13/02/2015.
//
//

#import <MapKit/MapKit.h>

@interface SGMapHelper : NSObject

+ (MKMapRect)mapRectForAnnotations:(NSArray<id<MKAnnotation>> *)annos;

@end
