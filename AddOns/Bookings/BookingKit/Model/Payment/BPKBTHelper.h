//
//  BPKBTHelper.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef BRAINTREE

#import "BPKForm.h"

@protocol BPKBTHelperDelegate;

@interface BPKBTHelper : NSObject

@property (nonatomic, weak) id<BPKBTHelperDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url;

- (void)makePaymentOverController:(UIViewController *)controller
                       completion:(void(^)(BPKForm *, NSError *))completion;

@end

@protocol BPKBTHelperDelegate <NSObject>

@optional

- (void)btHelperWillLoadPaymentForm:(BPKBTHelper *)helper;

@end

#endif
