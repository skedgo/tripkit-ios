//
//  UIView+FindFirstResponder.m
//  TripKit
//
//  Created by Adrian Schönig on 9/02/11.
//  Copyright 2011 SkedGo. All rights reserved.
//

#import "UIView+FindFirstResponder.h"

@implementation UIView (FindFirstResponder)

/**
 Thanks to http://stackoverflow.com/questions/1823317/get-the-current-first-responder-without-using-a-private-api
 */
- (UIView *)findFirstResponder
{
  if (self.isFirstResponder) {        
    return self;     
  }
  
  for (UIView *subView in self.subviews) {
    UIView *firstResponder = [subView findFirstResponder];
    
    if (firstResponder != nil) {
      return firstResponder;
    }
  }
  
  return nil;
}

@end
