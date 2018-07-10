//
//  TKImageCacher.m
//  TripKit
//
//  Created by Adrian Schoenig on 29/11/2013.
//
//

#import "TKImageCacher.h"

#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"

#if TARGET_OS_IPHONE

@interface TKImageCacher ()

@property (nonatomic, strong) NSCache *monochromeImageCache;

@end

@implementation TKImageCacher

+ (TKImageCacher *)sharedInstance {
  DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
    return [[self alloc] init];
  });
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.monochromeImageCache = [[NSCache alloc] init];
  }
  return self;
}

- (UIImage *)monochromeImageForName:(NSString *)imageName
{
  if (!imageName) {
    return nil;
  }
  
  UIImage *image = [self.monochromeImageCache objectForKey:imageName];
  if (! image) {
    image = [UIImage imageNamed:imageName];
    if (!image) {
      image = [TKStyleManager optionalImageNamed:imageName];
    }
    
    if (image) {
      image = [image monochromeImage];
      [self.monochromeImageCache setObject:image forKey:imageName];
    } else {
      DLog(@"Missing image: %@", imageName);
    }
  }
  return image;
}

@end

#endif
