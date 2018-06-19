//
//  ImageAnnotationView.m
//  Tracker
//
//  Created by Adrian Schönig on 13/04/10.
//  Copyright 2010 Adrian Schönig. All rights reserved.
//

#import "ASImageAnnotationView.h"

@import QuartzCore;

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#import "TripKitUI/TripKitUI-Swift.h"
#endif

#import "UIView+BearingRotation.h"

// Animation defines
#define ASAnimationSpeedMinor 0.25f // seconds
#define ASDragPinOffset 30 // pixels... distance that pixels jump up when dragging

@interface ASImageAnnotationView ()

@property (nonatomic, weak) UIImageView *imageView;

@end

@implementation ASImageAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];

  self.centerOffset = CGPointMake(0, self.image.size.height * -0.5f);
	
	return self;
}

- (void)setAnnotation:(id<MKAnnotation>)annotation
{
  [super setAnnotation:annotation];

  if (! [self.annotation respondsToSelector:@selector(pointImage)]) {
    return;
  }
  
  id<STKDisplayablePoint> displayable = (id<STKDisplayablePoint>) self.annotation;
  
	UIImage *image = [displayable pointImage];
  if (!self.imageView || !CGSizeEqualToSize(self.imageView.image.size, image.size)) {
    [self.imageView removeFromSuperview];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:imageView];
    self.imageView = imageView;

    CGRect frame = self.frame;
    frame.size = imageView.frame.size;
    self.frame = frame;
  } else {
    self.imageView.image = image;
  }
  
  if ([displayable respondsToSelector:@selector(pointImageURL)]) {
    NSURL *imageURL = [displayable pointImageURL];
    BOOL asTemplate = [displayable pointImageIsTemplate];
    [self.imageView setImageWithURL:imageURL asTemplate:asTemplate placeholderImage:image];
  }
}

- (void)rotateImageForBearing:(CGFloat)bearing
{
	[self.imageView rotateForBearing:bearing];
}

- (void)setDragState:(MKAnnotationViewDragState)newState animated:(BOOL)animated
{
  if (YES == animated) {
    if (MKAnnotationViewDragStateStarting == newState) {
      // trigger animation
      [UIView beginAnimations:@"AnnotationMoveUp" context:nil];
      [UIView setAnimationDelegate:self];
      [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
      [UIView setAnimationDuration:ASAnimationSpeedMinor];
      [self setCenter:CGPointMake(self.center.x, self.center.y - ASDragPinOffset)];
      [UIView commitAnimations];
      
    } else if (MKAnnotationViewDragStateEnding == newState) {
      // trigger animation
      [UIView beginAnimations:@"AnnotationHopUp" context:nil];
      [UIView setAnimationDelegate:self];
      [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
      [UIView setAnimationDuration:ASAnimationSpeedMinor];
      [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
      [self setCenter:CGPointMake(self.center.x, self.center.y - ASDragPinOffset)];
      [UIView commitAnimations];
    }

  } else {
    // don't animate
    if (MKAnnotationViewDragStateStarting == newState) {
      [self setCenter:CGPointMake(self.center.x, self.center.y - ASDragPinOffset)];
      
    } else if (MKAnnotationViewDragStateEnding == newState) {
      [self setCenter:CGPointMake(self.center.x, self.center.y - ASDragPinOffset)];
    }
  }

  [super setDragState:newState animated:animated];
}

#pragma mark -
#pragma mark Animations

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
#pragma unused(finished, context)
  
  if ([@"AnnotationMoveUp" isEqual: animationID]) {
    // done dragging started animation
    if (self.dragState == MKAnnotationViewDragStateStarting) {
      self.dragState = MKAnnotationViewDragStateDragging;
    }
    
  } else if ([@"AnnotationHopUp" isEqual: animationID]) {
    [UIView beginAnimations:@"AnnotationHopDown" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:ASAnimationSpeedMinor];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [self setCenter:CGPointMake(self.center.x, self.center.y + ASDragPinOffset)];
    [UIView commitAnimations];
    
    
  } else if ([@"AnnotationHopDown" isEqual: animationID]) {
    // done dragging ended animation
    if (self.dragState == MKAnnotationViewDragStateEnding) {
      self.dragState = MKAnnotationViewDragStateNone;
    }
  }
}

@end
