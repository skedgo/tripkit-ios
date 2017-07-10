//
//  MKMapView+ZoomToAnnotations.h
//  TripGo
//
//  Created by Adrian Schönig on 24/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKMapView(ZoomToAnnotations)

/**
 Zooms the map view to the selected annotations.

@param annos    A list of id<MKAnnotation> objects
@param animated boolean
*/
- (void)zoomToAnnotations:(NSArray<id<MKAnnotation>> *)annos
              edgePadding:(UIEdgeInsets)insets
                 animated:(BOOL)animated;

/**
 Zooms the map view so that the selected annotations are displayed in the lower part
 of the map view. The multiplier should be set to the percentage of the that lower part.
 
 @note don't call this while animating a resize of the map since that will make the map jump around.
 
 @param annos           A list of id<MKAnnotation> objects
 @param lowerMultiplier Vertical position: 0 bottom of map, 0.5 middle, 1 top
 @param animated        boolean
 */
- (void)zoomAnnotations:(NSArray<id<MKAnnotation>> *)annos
      toLowerProportion:(CGFloat)lowerMultiplier
               animated:(BOOL)animated;

/**
 @param annos A list of id<MKAnnotation> objects
 
 @return Whether the map contains at least one of the annotations
 */
- (BOOL)visibleMapContainsAny:(NSArray<id<MKAnnotation>> *)annos;

/**
 @param annos A list of id<MKAnnotation> objects
 
 @return Whether the map contains all of the annotations
 */
- (BOOL)visibleMapContainsAll:(NSArray<id<MKAnnotation>> *)annos;

@end

NS_ASSUME_NONNULL_END
