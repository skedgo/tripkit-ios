//
//  UIImage+Variations.m
//  TripKit
//
//  Created by Adrian Schoenig on 7/08/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "UIImage+Variations.h"

#if TARGET_OS_IPHONE

@import QuartzCore;
@import CoreImage;

@implementation UIImage (Variations)

- (UIImage *)imageWithTintColor:(UIColor *)tintColor
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

- (UIImage *)imageOnBackgroundImage:(UIImage *)background
{
  CGRect drawRect = CGRectMake(0, 0, background.size.width, background.size.height);
  
  UIGraphicsBeginImageContextWithOptions(drawRect.size, NO, 0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextTranslateCTM(context, 0, drawRect.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  
  // draw background image
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGContextDrawImage(context, drawRect, background.CGImage);
  
  // draw original image
  CGRect frontRect = CGRectMake((drawRect.size.width - self.size.width) / 2,
                                (drawRect.size.height - self.size.height) / 2,
                                self.size.width,
                                self.size.height);
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGContextDrawImage(context, frontRect, self.CGImage);
  
  UIImage *combinedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return combinedImage;
}

@end

#endif
