//
//  ImageAnnotationView.h
//  Tracker
//
//  Created by Adrian Schönig on 13/04/10.
//  Copyright 2010 Adrian Schönig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ASImageAnnotationView : MKAnnotationView

- (void)rotateImageForBearing:(CGFloat)bearing;

@end
