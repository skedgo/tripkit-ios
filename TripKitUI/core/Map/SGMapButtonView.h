//
//  SGMapButtonView.h
//  TripGo
//
//  Created by Adrian Schoenig on 26/09/13.
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface SGMapButtonView : UIView

+ (CGRect)mapButtonFrameForViewController:(UIViewController *)viewController
                          withExtraOffset:(CGFloat)extraOffset;

@property (nonatomic, copy) NSArray *items;

/**
 *  For some reason that we are not fully understand, there might be some additional
 *  space between the leftmost map button and the left edge of the view. An example
 *  of where this happens is SGMapDraggerViewController while in SearchMapVC, this is
 *  not happening. When this property is set to true, the view will try to offset that
 *  additional space.
 *
 *  Note, this property must be set 'before' setItems:animated: method is called to
 *  have effect.
 */
@property (nonatomic, assign) BOOL compensateHorizontalOffset;

@property (nonatomic, assign) CGFloat mapViewBottomLayoutMarginOffset;

- (id)initWithFrame:(CGRect)frame forMapView:(MKMapView *)mapView;

- (void)setItems:(NSArray *)items animated:(BOOL)animated;

@end
