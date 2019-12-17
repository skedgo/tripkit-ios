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

- (UIImage *)tk_imageOnBackgroundImage:(UIImage *)background
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

- (UIImage *)tk_monochromeImage
{
  CIImage *inputImage = [[CIImage alloc] initWithImage:self];
  CIFilter *monochrome = [CIFilter filterWithName:@"CIColorMonochrome"];
  [monochrome setDefaults];
  [monochrome setValue:inputImage forKey:kCIInputImageKey];
  
  // make greyscale
  CIColor *color = [CIColor colorWithRed:0.5 green:0.5 blue:0.5];
  [monochrome setValue:color forKeyPath:@"inputColor"];
  
  CIImage *outputImage = [monochrome valueForKey:kCIOutputImageKey];
  // define context
  CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @YES}]; // use software renderer, so that we can do this in the background
  
  CGImageRef cgImage = [context createCGImage:outputImage
                                     fromRect:outputImage.extent];
  UIImage *image = [UIImage imageWithCGImage:cgImage scale:self.scale orientation:UIImageOrientationUp];
  CGImageRelease(cgImage);
  return image;
}

@end

#endif
