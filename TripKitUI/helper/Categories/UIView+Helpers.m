//
//  UIView+Helpers.m
//  TripKit
//
//  Created by Adrian Schönig on 23/04/12.
//  Copyright (c) 2012 SkedGo. All rights reserved.
//

#import "UIView+Helpers.h"

#import <QuartzCore/QuartzCore.h>

@implementation UIView (Helpers)

- (void)removeAllSubviews
{
  NSArray *subviewCopy = [[self subviews] copy];
  for (UIView *view in subviewCopy) {
    [view removeFromSuperview];
  }
}

@end
