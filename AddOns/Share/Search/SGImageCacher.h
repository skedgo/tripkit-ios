//
//  SGImageCacher.h
//  TripGo
//
//  Created by Adrian Schoenig on 29/11/2013.
//
//

#import <UIKit/UIKit.h>

@interface SGImageCacher : NSObject

+ (SGImageCacher *)sharedInstance;

- (UIImage *)monochromeImageForName:(NSString *)imageName;

@end
