//
//  TripURLProvider.h
//  TripGo
//
//  Created by Adrian Schoenig on 13/11/2013.
//
//

#import <UIKit/UIKit.h>

@protocol SGURLShareable <NSObject>
- (NSURL *)shareURL;
@optional
- (NSURL *)saveURL;
- (void)setShareURL:(NSURL *)shareURL;
@end

@interface TKShareURLProvider : UIActivityItemProvider

+ (void)getShareURLForShareable:(id<SGURLShareable>)shareable
                   allowLongURL:(BOOL)longURL
                        success:(void (^)(NSURL *url))success
                        failure:(void (^)())failure;

+ (NSURL *)getShareURLForShareable:(id<SGURLShareable>)shareable
                      allowLongURL:(BOOL)longURL
                     allowBlocking:(BOOL)allowBlocking;

@end
