//
//  TripURLProvider.m
//  TripGo
//
//  Created by Adrian Schoenig on 13/11/2013.
//
//

#import "TKShareURLProvider.h"

@import SGCoreKit;

#define SECONDS_TO_WAIT 10

@implementation TKShareURLProvider

+ (void)getShareURLForShareable:(id<SGURLShareable>)shareable
                   allowLongURL:(BOOL)allowLong
                        success:(void (^)(NSURL *url))success
                        failure:(void (^)())failure
{
  NSURL *shareURL = [shareable shareURL];
  if (shareURL) {
    success(shareURL);

  } else if ([shareable respondsToSelector:@selector(saveURL)]) {
    // can we fetch the shareURL?
    NSURL *rawSaveURL = [shareable saveURL];
    NSURL *saveURL = [self saveURLForBaseSaveURL:rawSaveURL
                                    allowLongURL:allowLong];
    if (saveURL) {
      [SVKServer GET:saveURL
               paras:nil
          completion:
       ^(id  _Nullable responseObject, NSError * _Nullable error) {
#pragma unused(error)
         NSURL *newShareURL;
         if ([responseObject isKindOfClass:[NSDictionary class]]) {
           NSString *urlString = responseObject[@"url"];
           newShareURL = [NSURL URLWithString:urlString];
           if ([shareable respondsToSelector:@selector(setShareURL:)]) {
             [shareable setShareURL:newShareURL];
           }
         }
         
         if (newShareURL) {
           success(newShareURL);
         } else if (failure) {
           failure();
         }
       }];
    } else {
      failure();
    }
  }
}

+ (nullable NSURL *)getShareURLForShareable:(id<SGURLShareable>)shareable
                               allowLongURL:(BOOL)allowLong
                              allowBlocking:(BOOL)allowBlocking
{
  NSURL *shareURL = [shareable shareURL];
  if (shareURL) {
    return shareURL;
  }
  
  if (allowBlocking && [shareable respondsToSelector:@selector(saveURL)]) {
    // can we fetch the shareURL?
    NSURL *rawSaveURL = [shareable saveURL];
    NSURL *saveURL = [self saveURLForBaseSaveURL:rawSaveURL
                                    allowLongURL:allowLong];
    if (!saveURL) {
      return nil;
    }
    
    id result = [SVKServer syncURL:saveURL timeout:SECONDS_TO_WAIT];
    if ([result isKindOfClass:[NSDictionary class]]) {
      NSString *urlString = result[@"url"];
      shareURL = [NSURL URLWithString:urlString];
      if ([shareable respondsToSelector:@selector(setShareURL:)]) {
        [shareable setShareURL:shareURL];
      }
    }
    if (shareURL) {
      return shareURL;
    }
  }
  return nil;
}

- (id)item
{
  if ([[self activityType] rangeOfString:@"kSGAction"].location != NSNotFound)
    return nil; // don't do this for app action activities
  
  id placeholder = [self placeholderItem];
  if ([placeholder conformsToProtocol:@protocol(SGURLShareable)]) {
    id<SGURLShareable> shareable = placeholder;
    NSURL *url = [[self class] getShareURLForShareable:shareable
                                          allowLongURL:NO
                                         allowBlocking:YES];
    if (url) {
      return url;
    }
  }
  
  return [NSURL URLWithString:@"http://skedgo.com/tripgo"];
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
#pragma unused(activityViewController)
  return [NSURL URLWithString:@"http://skedgo.com/tripgo"];
}

#pragma mark - Private helpers

+ (NSURL *)saveURLForBaseSaveURL:(NSURL *)url
                    allowLongURL:(BOOL)allowLong
{
  if (allowLong) {
    NSString *absolute = [url absoluteString];
    NSString *newAbsolute = [absolute rangeOfString:@"?"].location != NSNotFound
      ? [absolute stringByAppendingString:@"&long=1"]
      : [absolute stringByAppendingString:@"?long=1"];
    return [NSURL URLWithString:newAbsolute];
    
  } else {
    return url;
  }
}

@end
