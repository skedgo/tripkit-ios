//
//  BPKSever.m
//  TripKit
//
//  Created by Kuan Lun Huang on 16/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKServerUtil.h"

@implementation BPKServerUtil

+ (void)requestFormForBookingURL:(NSURL *)bookingURL
                        postData:(NSDictionary *)postData
                      completion:(SGServerGenericBlock)completion
{
  DLog(@"requesting form from: %@ with data %@", bookingURL, postData);
  
  // We'll call back on the main thread
  void (^handler)(NSInteger, NSDictionary<NSString *, id> *, id, NSData *, NSError *) = ^(NSInteger status, NSDictionary<NSString *, id> *headers, id response, NSData *data, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(status, headers, response, data, error);
    });
  };

  // Matches TKSettings
  NSNumber *bsb = nil;
#ifdef DEBUG
  BOOL useSandbox = [[NSUserDefaults sharedDefaults] boolForKey:@"profileBookingsUseSandbox"];
  bsb = @(useSandbox);
#else
  if ([[NSUserDefaults sharedDefaults] boolForKey:@"profileBookingsUseSandbox"]) {
    bsb = @(YES);
  }
#endif
  
  if (postData) {
    if ([bsb boolValue]) {
      NSMutableDictionary *adjusted = [NSMutableDictionary dictionaryWithDictionary:postData];
      adjusted[@"bsb"] = bsb;
      postData = adjusted;
    }
    
    [SVKServer POST:bookingURL
              paras:postData
         completion:handler];
    
  } else {
    NSMutableDictionary *paras = [NSMutableDictionary dictionary];
    
    // Note that, it's possible that the URL already contains some parameters, for instance,
    // ttps://bigbang.buzzhives.com/satapp-beta/auth/signin/6adac22c-9485-402d-ab15-6498ca03d640?op=add_cc
    NSURLComponents *components = [NSURLComponents componentsWithString:bookingURL.absoluteString];
    for (NSURLQueryItem *item in components.queryItems) {
      [paras setObject:item.value forKey:item.name];
    }
    
    // Don't foget to indicate whether we are in sandbox environment.
    if ([bsb boolValue]) {
      [paras setObject:bsb forKey:@"bsb"];
    }
    
    [SVKServer GET:bookingURL
             paras:paras
        completion:handler];
  }
}

@end
