//
//  TKPermissionManager.h
//  Welcome
//
//  Created by Adrian Schoenig on 4/09/12.
//  Copyright (c) 2012 Adrian Schoenig. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TKPermissionCompletionBlock)(BOOL enabled);
typedef void(^TKPermissionsOpenSettingsHandler)(void);

typedef NS_ENUM(NSInteger, TKAuthorizationStatus) {
  TKAuthorizationStatusNotDetermined = 0,
  TKAuthorizationStatusRestricted,
  TKAuthorizationStatusDenied,
  TKAuthorizationStatusAuthorized
};

FOUNDATION_EXPORT NSString *const TKPermissionsChangedNotification;

@interface TKPermissionManager : NSObject

@property (nonatomic, strong, nullable) TKPermissionsOpenSettingsHandler openSettingsHandler;

// these are the main interface methods

/**
 * Is the app capable and authorized to use these kind of permissions?
 */
- (BOOL)isAuthorized;

// subclasses need to implement these
- (BOOL)featureIsAvailable;
- (void)askForPermission:(TKPermissionCompletionBlock)completion;
- (BOOL)authorizationRestrictionsApply;
- (TKAuthorizationStatus)authorizationStatus;
- (NSString *)authorizationAlertText;

@end

NS_ASSUME_NONNULL_END
