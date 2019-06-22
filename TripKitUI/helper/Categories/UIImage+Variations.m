//
//  UIImage+Variations.m
//  TripKit
//
//  Created by Adrian Schoenig on 7/08/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "UIImage+Variations.h"

@import CoreImage;

@implementation UIImage (Variations)

- (UIImage *)tk_imageWithTintColor:(UIColor *)tintColor
{
  CGRect drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
  
  UIGraphicsBeginImageContextWithOptions(drawRect.size, NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextTranslateCTM(context, 0, self.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  
  // draw original image
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGContextDrawImage(context, drawRect, self.CGImage);
  
  // draw color atop
  CGContextSetFillColorWithColor(context, tintColor.CGColor);
  CGContextSetBlendMode(context, kCGBlendModeSourceAtop);
  CGContextFillRect(context, drawRect);
  
  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return tintedImage;
}

@end
