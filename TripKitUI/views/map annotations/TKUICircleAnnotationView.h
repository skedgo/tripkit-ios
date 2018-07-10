//
//  TKUICircleAnnotationView.h
//  TripKit
//
//  Created by Adrian Schönig on 16/06/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

@import MapKit;

@interface TKUICircleAnnotationView : MKAnnotationView

@property (nonatomic, assign) BOOL isLarge;
@property (nonatomic, strong) UIColor *circleColor;
@property (nonatomic, assign) BOOL isFaded;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation 
               drawLarge:(BOOL)large 
         reuseIdentifier:(NSString *)reuseIdentifier;

@end
