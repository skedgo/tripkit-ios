//
//  NSString+Sizing.h
//  TripKit
//
//  Created by Adrian Schoenig on 20/09/13.
//
//

#if SWIFT_PACKAGE
#import <TripKitObjc/TKCrossPlatform.h>
#else
#import "TKCrossPlatform.h"
#endif

@interface NSString (Sizing)

- (CGSize)sizeWithFont:(TKFont *)font maximumWidth:(CGFloat)maxWidth;

@end
