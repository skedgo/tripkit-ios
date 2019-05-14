//
//  UIImage+Variations.h
//  TripKit
//
//  Created by Adrian Schoenig on 7/08/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKCrossPlatform.h"

#if TARGET_OS_IPHONE

NS_ASSUME_NONNULL_BEGIN

@interface TKImage (Variations)

- (TKImage *)imageWithTintColor:(TKColor *)tintColor;

- (TKImage *)imageOnBackgroundImage:(TKImage *)background;

@end


NS_ASSUME_NONNULL_END

#endif
