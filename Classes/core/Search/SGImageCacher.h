//
//  SGImageCacher.h
//  TripKit
//
//  Created by Adrian Schoenig on 29/11/2013.
//
//

#import "SGKCrossPlatform.h"

#if TARGET_OS_IPHONE

@interface SGImageCacher : NSObject

+ (SGImageCacher *)sharedInstance;

- (UIImage *)monochromeImageForName:(NSString *)imageName;

@end

#endif
