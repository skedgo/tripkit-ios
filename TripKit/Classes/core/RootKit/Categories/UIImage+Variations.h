//
//  UIImage+Variations.h
//  TripKit
//
//  Created by Adrian Schoenig on 7/08/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "SGKCrossPlatform.h"

#if TARGET_OS_IPHONE

NS_ASSUME_NONNULL_BEGIN

@interface SGKImage (Variations)

- (SGKImage *)tk_imageWithTintColor:(SGKColor *)tintColor;

- (SGKImage *)tk_imageOnBackgroundImage:(SGKImage *)background;

- (SGKImage *)tk_monochromeImage;

@end


NS_ASSUME_NONNULL_END

#endif
