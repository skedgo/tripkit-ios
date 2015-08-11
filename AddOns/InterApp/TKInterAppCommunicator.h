//
//  TKInterAppCommunicator.h
//  TripGo
//
//  Created by Adrian Schoenig on 11/08/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TKSegment;

NS_ASSUME_NONNULL_BEGIN

@interface TKInterAppCommunicator : NSObject

#pragma mark - Turn-by-turn

+ (BOOL)canOpenInMapsApp:(TKSegment *)segment;

+ (void)openSegmentInMapsApp:(TKSegment *)segment
           forViewController:(UIViewController *)controller
                 initiatedBy:(nullable id)sender;

#pragma mark - Taxi / ride sharing apps

/**
 */
+ (BOOL)canHandleExternalActions:(TKSegment *)segment;

/**
 This will handle the external actions of the specified segments either by launching the external app (if there's only one action) or by presenting a sheet of actions to take for the user.
 @param segment A segment for which `canHandleExternalActions` returned YES before.
 @param controller A controller to present the action sheet on
 @param sender An optional sender on which to anchor the action sheet
 @param openURLHandler Will be called if the user selects an action that requires opening a website. If `nil` the webpage will be opened by opening Safari.
 @param openStoreHandler Will be called with an iTunes app ID if the user select an action that requires installing an app. If `nil` the iTunes Store page will be opened via URL.
 */
+ (void)handleExternalActions:(TKSegment * __nonnull)segment
            forViewController:(UIViewController * __nonnull)controller
                  initiatedBy:(nullable id)sender
               openURLHandler:(nullable void (^)(NSURL * __nonnull, NSString * __nullable))openURLHandler
             openStoreHandler:(nullable void (^)(NSNumber * __nonnull))openStoreHandler;

@end

NS_ASSUME_NONNULL_END
