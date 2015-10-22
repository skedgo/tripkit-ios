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

/**
 Opens the segment in a maps app. Either directly in Apple Maps if nothing else is installed, or it will prompt for using Google Maps or Waze.
 @param segment A segment for which `canOpenInMapsApp` returns YES
 @param controller A controller to present the optional action sheet on
 @param sender An optional sender on which to anchor the optional action sheet
 @param currentLocationHandler Will be called to check if turn-by-turn navigation should start at the current location or at the segment's start location. If `nil` it will start at the current location.
 */
+ (void)openSegmentInMapsApp:(TKSegment *)segment
           forViewController:(UIViewController *)controller
                 initiatedBy:(nullable id)sender
      currentLocationHandler:(nullable BOOL (^)(TKSegment * __nonnull))currentLocationHandler;

#pragma mark - Taxi / ride sharing apps

+ (BOOL)canHandleExternalActions:(TKSegment *)segment;

/**
 This will handle the external actions of the specified segments either by launching the external app (if there's only one action) or by presenting a sheet of actions to take for the user.
 @param segment A segment for which `canHandleExternalActions` returns YES
 @param controller A controller to present the optional action sheet on
 @param sender An optional sender on which to anchor the optional action sheet
 @param currentLocationHandler Will be called to check if the external action should start at the current location or at the segment's start location. If `nil` it will start at the current location.
 @param openURLHandler Will be called if the user selects an action that requires opening a website. If `nil` the webpage will be opened by opening Safari.
 @param openStoreHandler Will be called with an iTunes app ID if the user select an action that requires installing an app. If `nil` the iTunes Store page will be opened via URL.
 @param completionHandler Called when any action is triggered.
 */
+ (void)handleExternalActions:(TKSegment * __nonnull)segment
            forViewController:(UIViewController * __nonnull)controller
                  initiatedBy:(nullable id)sender
       currentLocationHandler:(nullable BOOL (^)(TKSegment * __nonnull))currentLocationHandler
               openURLHandler:(nullable void (^)(NSURL * __nonnull, NSString * __nullable))openURLHandler
             openStoreHandler:(nullable void (^)(NSNumber * __nonnull))openStoreHandler
            completionHandler:(nullable void (^)(NSString * __nonnull))completionHandler;

@end

NS_ASSUME_NONNULL_END
