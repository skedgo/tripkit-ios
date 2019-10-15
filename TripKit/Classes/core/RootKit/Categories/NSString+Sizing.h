//
//  NSString+Sizing.h
//  TripKit
//
//  Created by Adrian Schoenig on 20/09/13.
//
//

#import "TKCrossPlatform.h"

@interface NSString (Sizing)

- (CGSize)sizeWithFont:(TKFont *)font maximumWidth:(CGFloat)maxWidth;

@end
