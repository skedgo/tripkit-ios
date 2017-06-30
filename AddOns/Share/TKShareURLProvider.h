//
//  TripURLProvider.h
//  TripGo
//
//  Created by Adrian Schoenig on 13/11/2013.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SGURLShareable <NSObject>
@property (nullable, readonly) NSURL *shareURL;
@optional
- (nullable NSURL *)saveURL;
- (void)setShareURL:(NSURL *)shareURL;
@end

@interface TKShareURLProvider : UIActivityItemProvider

+ (void)getShareURLForShareable:(id<SGURLShareable>)shareable
                   allowLongURL:(BOOL)longURL
                        success:(void (^)(NSURL *url))success
                        failure:(nullable void (^)())failure;

+ (nullable NSURL *)getShareURLForShareable:(id<SGURLShareable>)shareable
                      allowLongURL:(BOOL)longURL
                     allowBlocking:(BOOL)allowBlocking;

@end

NS_ASSUME_NONNULL_END
