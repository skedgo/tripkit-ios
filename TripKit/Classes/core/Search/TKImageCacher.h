//
//  TKImageCacher.h
//  TripKit
//
//  Created by Adrian Schoenig on 29/11/2013.
//
//

#import "TKCrossPlatform.h"

#if TARGET_OS_IPHONE

@interface TKImageCacher : NSObject

+ (TKImageCacher *)sharedInstance;

- (UIImage *)monochromeImageForName:(NSString *)imageName;

@end

#endif
